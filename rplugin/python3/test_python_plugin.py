from __future__ import annotations
import contextlib
import dataclasses
import enum
import json
import re
import textwrap
from typing import Generator, TypedDict

import httpx
import pynvim
import pynvim.api

JsonType = int | float | bool | str | None | list["JsonType"] | dict[str, "JsonType"]


def _wrap_width(nvim: pynvim.Nvim, default: int = 80) -> int:
    tw = int(
        getattr(nvim.options, "get", lambda _k, _d=None: None)("textwidth", 0) or 0
    )
    if tw > 0:
        return tw

    cc = str(
        getattr(nvim.options, "get", lambda _k, _d=None: None)("colorcolumn", "") or ""
    )
    # colorcolumn can be like "80", "80,100", "+1"
    m = re.search(r"(\d+)", cc)
    if m:
        return int(m.group(1))

    return default


_LIST_RE = re.compile(r"^(\s*)([-*+]|\d+[.)])(\s+)(.*)$")


def _is_role_header_line(line: str) -> bool:
    clean = " ".join(line.lower().split())
    return clean in {"# system", "# user", "# assistant"}


def _reflow_paragraph(lines: list[str], width: int) -> list[str]:
    """
    Wrap a paragraph while preserving indentation and common list prefixes.
    """
    if not lines:
        return []

    # Keep leading indentation of the first line
    first = lines[0]
    if first.strip() == "":
        return lines[:]

    # Do not touch role headers
    if _is_role_header_line(first):
        return lines[:]

    # If single line already within width, leave it
    if len(lines) == 1 and len(lines[0]) <= width:
        return lines[:]

    m = _LIST_RE.match(first)
    if m:
        indent, bullet, gap, rest = m.groups()
        initial_indent = f"{indent}{bullet}{gap}"
        subsequent_indent = " " * len(initial_indent)
        text = " ".join(
            [rest.strip()] + [ln.strip() for ln in lines[1:] if ln.strip() != ""]
        )
        wrapped = textwrap.fill(
            text,
            width=width,
            initial_indent=initial_indent,
            subsequent_indent=subsequent_indent,
            break_long_words=False,
            break_on_hyphens=False,
        )
        return wrapped.splitlines()

    m_indent = re.match(r"^\s*", first)
    indent = m_indent.group(0) if m_indent is not None else ""
    initial_indent = indent
    subsequent_indent = indent
    text = " ".join([ln.strip() for ln in lines if ln.strip() != ""])
    wrapped = textwrap.fill(
        text,
        width=width,
        initial_indent=initial_indent,
        subsequent_indent=subsequent_indent,
        break_long_words=False,
        break_on_hyphens=False,
    )
    return wrapped.splitlines()


def _reflow_outside_fences(buf_lines: list[str], width: int) -> list[str]:
    """
    Wrap only outside ``` fenced blocks. Leaves fenced content unchanged.
    Paragraphs are separated by blank lines, role headers, and fence lines.
    """
    out: list[str] = []
    para: list[str] = []
    in_fence = False

    def flush_para() -> None:
        nonlocal para
        if para:
            out.extend(_reflow_paragraph(para, width))
            para = []

    for line in buf_lines:
        stripped = line.strip()

        if stripped.startswith("```"):
            flush_para()
            in_fence = not in_fence
            out.append(line)
            continue

        if in_fence:
            out.append(line)
            continue

        if _is_role_header_line(line):
            flush_para()
            out.append(line)
            continue

        if stripped == "":
            flush_para()
            out.append(line)
            continue

        # Keep single very-indented lines (often meant to be literal) as their own paragraph
        if line.startswith("\t") or (
            len(line) - len(line.lstrip(" ")) >= 4 and not para
        ):
            flush_para()
            out.append(line)
            continue

        para.append(line)

    flush_para()
    return out


def _notify(nvim: pynvim.Nvim, msg: str) -> None:
    # json.dumps gives safe quoting for :echomsg
    nvim.command("echohl ModeMsg")
    nvim.command(f"echomsg {json.dumps(msg)}")
    nvim.command("echohl None")
    # Make sure the user sees it immediately during long sync work
    nvim.command("redraw")


@contextlib.contextmanager
def _busy(nvim: pynvim.Nvim, msg: str) -> Generator[None, None, None]:
    """
    User feedback without modifying editor options (no guicursor/mouse/etc).
    """
    try:
        _notify(nvim, msg)
    except Exception:
        pass
    try:
        yield
    finally:
        # Clear command area; keep the message in :messages via echomsg
        try:
            nvim.command("echo ''")
            nvim.command("redraw")
        except Exception:
            pass


class Role(enum.Enum):
    SYSTEM = enum.auto()
    USER = enum.auto()
    ASSISTANT = enum.auto()


class InferenceServer(enum.Enum):
    OLLAMA = enum.auto()


def role_for_server(role: Role, server: InferenceServer) -> str:
    match (role, server):
        case (Role.SYSTEM, InferenceServer.OLLAMA):
            return "system"
        case (Role.USER, InferenceServer.OLLAMA):
            return "user"
        case (Role.ASSISTANT, InferenceServer.OLLAMA):
            return "assistant"
        case _:
            raise RuntimeError(
                f"Unsupported role/server configuration: {(role, server)}"
            )


@dataclasses.dataclass(frozen=True)
class MessageBlock:
    role: Role
    content: str
    header_lnum: int
    content_start_lnum: int
    content_end_lnum: int


class MessageModel(TypedDict):
    role: str
    content: str


class PayloadModel(TypedDict):
    model: str
    stream: bool
    temperature: float
    messages: list[MessageModel]


def _block_start_lnum(block: MessageBlock) -> int:
    return block.header_lnum if block.header_lnum != -1 else block.content_start_lnum


def _purge_trailing_assistant_blocks(
    blocks: list[MessageBlock],
    assistant_role: Role,
) -> tuple[list[MessageBlock], int | None]:
    end = len(blocks)
    while end > 0 and blocks[end - 1].role == assistant_role:
        end -= 1

    if end == len(blocks):
        return blocks, None

    cut_lnum = _block_start_lnum(blocks[end])
    return blocks[:end], cut_lnum


def _truncate_blocks_to_last_user_or_system(
    blocks: list[MessageBlock],
    user_role: Role,
    system_role: Role,
) -> tuple[list[MessageBlock], int | None]:
    last_user: int | None = None
    last_system: int | None = None

    for i, b in enumerate(blocks):
        if b.role == user_role:
            last_user = i
        elif b.role == system_role:
            last_system = i

    keep_end_idx: int | None = last_user if last_user is not None else last_system
    if keep_end_idx is None:
        return [], 0

    keep_count = keep_end_idx + 1
    if keep_count == len(blocks):
        return blocks, None

    cut_lnum = _block_start_lnum(blocks[keep_count])
    return blocks[:keep_count], cut_lnum


def _apply_buffer_truncation(buf: pynvim.api.Buffer, cut_lnum: int | None) -> None:
    if cut_lnum is None:
        return
    if cut_lnum < 0:
        cut_lnum = 0
    buf[cut_lnum:] = []


def _trim_buffer_tail_for_assistant_append(buf: pynvim.api.Buffer) -> None:
    """
    Ensure the next appended line ("# assistant") will appear exactly one newline
    after the last non-whitespace content in the buffer.

    Concretely:
      - Drop trailing whitespace-only lines at EOF.
      - Strip trailing spaces/tabs from the final remaining line.
      - If stripping makes the final line empty, drop it too.
    """
    lines: list[str] = list(buf[:])

    # Drop trailing whitespace-only lines
    while lines and lines[-1].strip() == "":
        lines.pop()

    if not lines:
        buf[:] = []
        return

    # Strip trailing spaces/tabs from the last line
    last = lines[-1].rstrip(" \t")
    if last == "":
        lines.pop()
    else:
        lines[-1] = last

    buf[:] = lines


@pynvim.plugin
class TestPythonPlugin:
    def __init__(self, nvim: pynvim.Nvim) -> None:
        self.nvim = nvim

    def _parse_buffer(self) -> Generator[MessageBlock, None, None]:
        role_map: dict[str, Role] = {
            "# system": Role.SYSTEM,
            "# user": Role.USER,
            "# assistant": Role.ASSISTANT,
        }

        current_role: Role = Role.SYSTEM
        header_lnum: int = -1
        content_start_lnum: int = 0
        buff_lines: list[str] = []

        def flush(content_end_lnum: int) -> Generator[MessageBlock, None, None]:
            nonlocal buff_lines
            if not buff_lines:
                return
            content = "\n".join(buff_lines).strip("\n")
            buff_lines = []
            if content.strip() == "":
                return
            yield MessageBlock(
                role=current_role,
                content=content,
                header_lnum=header_lnum,
                content_start_lnum=content_start_lnum,
                content_end_lnum=content_end_lnum,
            )

        last_idx: int = -1
        for ii, line in enumerate(self.nvim.current.buffer):
            last_idx = ii
            clean = " ".join(line.lower().split())
            if clean in role_map:
                yield from flush(ii - 1)
                current_role = role_map[clean]
                header_lnum = ii
                content_start_lnum = ii + 1
            else:
                buff_lines.append(line)

        yield from flush(last_idx)

    def _send_ollama_once(self, payload: PayloadModel) -> str:
        url = "http://127.0.0.1:11434/v1/chat/completions"

        with httpx.Client(timeout=60.0) as client:
            resp = client.post(url, json=payload)
            resp.raise_for_status()
            data: JsonType = resp.json()

        if not isinstance(data, dict):
            raise RuntimeError(f"Malformed response from server: {data}")

        choices = data.get("choices")
        if not isinstance(choices, list) or not choices:
            raise RuntimeError("No choices in Ollama response")

        first_choice = choices[0]
        if not isinstance(first_choice, dict):
            raise RuntimeError(f"Malformed choice from server: {first_choice}")

        message = first_choice.get("message")
        if not isinstance(message, dict):
            raise RuntimeError("Malformed Ollama response")

        content = message.get("content")
        if not isinstance(content, str):
            raise RuntimeError("No assistant content in response")

        return content

    @pynvim.command("ChatSendOnce", nargs="0", sync=True)
    def chat_send_once(self, _: list[str]) -> None:
        buf = self.nvim.current.buffer

        blocks: list[MessageBlock] = list(self._parse_buffer())

        blocks, cut1 = _purge_trailing_assistant_blocks(blocks, Role.ASSISTANT)
        _apply_buffer_truncation(buf, cut1)

        if cut1 is not None:
            blocks = list(self._parse_buffer())

        if not any(b.role == Role.USER for b in blocks):
            self.nvim.err_write("ChatSendOnce: No user messages found.\n")
            return

        blocks, cut2 = _truncate_blocks_to_last_user_or_system(
            blocks,
            user_role=Role.USER,
            system_role=Role.SYSTEM,
        )
        _apply_buffer_truncation(buf, cut2)

        if cut2 is not None:
            blocks = list(self._parse_buffer())

        messages: list[MessageModel] = [
            {
                "role": role_for_server(b.role, InferenceServer.OLLAMA),
                "content": b.content,
            }
            for b in blocks
        ]

        payload: PayloadModel = {
            "model": "qwen2.5-coder:7b",
            "stream": False,
            "temperature": 0.2,
            "messages": messages,
        }

        with _busy(self.nvim, "ChatSendOnce: waiting for LLM response..."):
            try:
                reply = self._send_ollama_once(payload)
            except Exception as e:
                self.nvim.err_write(f"ChatSendOnce error: {e}\n")
                return

        with _busy(self.nvim, "ChatSendOnce: updating buffer..."):
            _trim_buffer_tail_for_assistant_append(buf)
            out: list[str] = ["", "# assistant", *reply.splitlines()]
            width = _wrap_width(self.nvim)
            buf[:] = _reflow_outside_fences(list(buf[:]) + out, width)

    @pynvim.command("ChatNewUser", nargs="0", sync=True)
    def chat_new_user(self, _: list[str]) -> None:
        buf = self.nvim.current.buffer

        blocks: list[MessageBlock] = list(self._parse_buffer())

        if not blocks:
            # Empty buffer → start with user header at top
            buf[:] = ["# user", ""]
            self.nvim.current.window.cursor = (2, 0)
            return

        last = blocks[-1]

        # Determine insertion point: exactly after the last block's content
        insert_lnum = last.content_end_lnum + 1

        # Trim trailing whitespace after the last block so spacing is deterministic
        # (only affects text *after* the last block)
        del buf[insert_lnum + 1 :]

        # Insert exactly one blank line + header
        buf[insert_lnum + 1 : insert_lnum + 1] = ["", "# user", ""]

        # Place cursor on the empty content line
        self.nvim.current.window.cursor = (insert_lnum + 3, 0)

    @pynvim.command("ChatNewSystem", nargs="0", sync=True)
    def chat_new_system(self, _: list[str]) -> None:
        buf = self.nvim.current.buffer

        blocks: list[MessageBlock] = list(self._parse_buffer())

        if not blocks:
            # Empty buffer → start with user header at top
            buf[:] = ["# system", ""]
            self.nvim.current.window.cursor = (2, 0)
            return

        last = blocks[-1]

        # Determine insertion point: exactly after the last block's content
        insert_lnum = last.content_end_lnum + 1

        # Trim trailing whitespace after the last block so spacing is deterministic
        # (only affects text *after* the last block)
        del buf[insert_lnum + 1 :]

        # Insert exactly one blank line + header
        buf[insert_lnum + 1 : insert_lnum + 1] = ["", "# system", ""]

        # Place cursor on the empty content line
        self.nvim.current.window.cursor = (insert_lnum + 3, 0)

    @pynvim.command("ChatReflow", nargs="0", sync=True)
    def chat_reflow(self, _: list[str]) -> None:
        buf = self.nvim.current.buffer
        width = _wrap_width(self.nvim)
        buf[:] = _reflow_outside_fences(list(buf[:]), width)
