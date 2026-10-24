# My Neovim config

Requires Neovim 0.12 or newer.

Plugins are managed by [lazy.nvim](https://lazy.folke.io), which installs
itself the first time Neovim starts. Clone this repo into `~/.config/nvim`
and open `nvim`; everything else downloads on its own.

```bash
git clone https://github.com/joshMaybell/nvim ~/.config/nvim
nvim
```

## Layout

| Path | What's in it |
| --- | --- |
| `init.lua` | Entry point, loads everything below |
| `lua/config/options.lua` | Editor settings |
| `lua/config/keymaps.lua` | General keymaps |
| `lua/config/functions.lua` | Global helpers you can call with `:lua` |
| `lua/config/autocmds.lua` | Autocommands and diagnostic display |
| `lua/config/lazy.lua` | Plugin manager bootstrap |
| `lua/plugins/*.lua` | One file per group of plugins |
| `rplugin/python3/` | Python remote plugin with the `:Chat*` commands |

## External tools

Most language servers and formatters are installed automatically by
[mason](https://github.com/mason-org/mason.nvim) into
`~/.local/share/nvim/mason`. Run `:Mason` to see them.

These come from the system instead, and are used only if present:

| Tool | Where it comes from |
| --- | --- |
| `tree-sitter` (0.26+) | Needed to build parsers, install from a package manager |
| `rust-analyzer` | `rustup component add rust-analyzer` |
| `sourcekit-lsp` | Swift toolchain (swiftly or Xcode) |
| `gleam` | The Gleam compiler |
| `elixir-ls` | Unpacked at `~/.elixir-ls/release/language_server.sh` |
| `nimlangserver` | `nimble install nimlangserver` |
| `pylint` | `pip install pylint` in the project's environment |

Neovim prepends `~/.cargo/bin`, `~/.local/share/swiftly/bin` and
`~/.local/bin` to its own `PATH` at startup, so these are found even when
Neovim is launched from somewhere that never sourced `~/.bashrc`. A server
whose command is missing is skipped silently; installing the toolchain later
is enough to make it start.

### Python: ruff or black

A project is treated as a ruff project when it has a `ruff.toml`, a
`.ruff.toml`, or a `[tool.ruff]` section in `pyproject.toml`. Those get
`ruff format`, `ruff check --select I --fix` for imports, and `ruff` for
linting. Everything else gets isort, black and pylint. Nothing to configure.

To decide explicitly, put a `.nvim.lua` in the project root:

```lua
vim.g.python_formatter = "ruff"   -- or "black"
```

Project-local config is Neovim's `'exrc'` feature and is enabled here. The
first time you open the project Neovim asks whether to trust the file, or you
can run `:trust` yourself. Nothing in it runs until you allow it. The same
file can override anything else, not just this variable.

`:LintInfo` shows which formatters and linters the current buffer will use.

Python linting only runs when `pylint` or `ruff` is on `PATH`. Installing it
per project rather than globally lets it see that project's packages.

### Swift

Swift gets its language server, `sourcekit-lsp`, from the Swift toolchain
rather than mason. Install the toolchain with
[swiftly](https://www.swift.org/install/linux/) (or Xcode on macOS) and make
sure `sourcekit-lsp` runs from a shell; Neovim adds
`~/.local/share/swiftly/bin` to its `PATH` itself.

- `sourcekit-lsp` is limited to Swift files. C, C++ and Objective-C stay
  with `clangd`.
- Completion, go-to-definition and diagnostics across files need a Swift
  package (`Package.swift`) or an Xcode project, and work best after one
  `swift build`, which produces the index the server reads.
- `<leader>ff` formats through the language server, which uses
  `swift-format` from the toolchain and any `.swift-format` file in the
  project.
- Highlighting and indentation come from the tree-sitter `swift` parser,
  which is installed automatically. It needs the `tree-sitter` CLI.

`:LspStatus` in a `.swift` buffer shows whether the server attached and
which directory it picked as the project root.

### Indentation

Neovim ships an indent script for most languages and those are used as they
are. Swift, gleam, elixir, toml and markdown have none, so for those the
tree-sitter `indents.scm` query is used instead. Without it those filetypes
fall back to `'smartindent'`, where `cc`, `o` and `=` reuse the current
line's indent rather than working out the expected one. Languages with their
own indent engine, C and C++ with `'cindent'` among them, are left alone.

## Keymaps

Leader is the space bar.

### Files and search

| Key | Action |
| --- | --- |
| `-` or `<leader>pv` | File explorer |
| `<leader>pf` | Find files |
| `<C-p>` | Find git files |
| `<leader>ps` | Grep for a string |
| `<leader>a` | Harpoon: mark this file |
| `<C-e>` | Harpoon: menu |
| `<leader>1` .. `<leader>5` | Harpoon: jump to a marked file |
| `<leader>u` | Undo tree |
| `<leader>gs` | Git status |

### Code

These only work where a language server is attached.

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `<leader>gd` | Go to definition in a vertical split |
| `gy` | Go to type definition |
| `<C-n>` | Hover documentation |
| `<leader>ff` | Format the buffer |
| `<leader>cd` | Diagnostics: cursor only, or the whole line |
| `<leader>cf` | Enter the diagnostics popup to scroll or copy the message |
| `grn` | Rename |
| `gra` | Code action |
| `grr` | References |
| `gri` | Implementation |

Diagnostics appear in a floating window when the cursor rests.

### Editing

| Key | Action |
| --- | --- |
| `J` / `K` (visual) | Move the selected lines down / up |
| `<leader>y` / `<leader>Y` | Yank to the system clipboard |
| `<leader>p` (visual) | Paste over the selection, keeping the register |
| `<leader>d` | Delete without touching registers |
| `<leader>o` / `<leader>O` | Empty line below / above, staying in normal mode |
| `<leader>s` | Replace the word under the cursor across the file |
| `<leader>h` | Clear search highlight |
| `<leader>v` | Vertical split |
| `<C-j>` / `<C-k>` | Down / up five lines |
| `<C-h>` / `<C-l>` | Left / right five columns |
| `gc` / `gb` | Toggle line / block comment |

### Completion

| Key | Action |
| --- | --- |
| `<C-j>` / `<C-k>` | Next / previous item |
| `<C-Space>` | Accept |
| `<C-n>` / `<C-p>` | Next / previous snippet placeholder |
| `<C-e>` | Close the menu |

When the menu is closed, `<C-j>`, `<C-k>`, `<C-h>` and `<C-l>` move the cursor
in insert mode instead.

### Terminals

| Key | Action |
| --- | --- |
| `<C-\><C-\>` | Toggle a floating terminal |
| `<C-\>1` .. `<C-\>9` | Toggle a numbered terminal |
| `<C-l><C-l>` | Clear the terminal |

### Collaboration

| Key | Action |
| --- | --- |
| `<leader>ef` | Teamtype: follow |
| `<leader>ej` | Teamtype: jump to cursor |

## Commands and functions

| Command | Action |
| --- | --- |
| `:lua ColorMyPencils("rose-pine")` | Switch colourscheme; `codedark` is the default |
| `:lua FormatAll()` | Format and write every file below the working directory |
| `:MarkdownPreview` | Preview the current markdown file in a browser |
| `:Ustatus`, `:Usync`, `:Uopen` | Unity project helpers |
| `:TeamtypeFollow`, `:TeamtypeJumpToCursor` | Collaborative editing |
| `:ChatNewUser`, `:ChatSendOnce`, `:ChatReflow` | Talk to a local Ollama model in a buffer |

The `:Chat*` commands come from the Python remote plugin. After changing
`rplugin/python3/`, run `:UpdateRemotePlugins` and restart.

## Maintenance

| Command | Action |
| --- | --- |
| `:Lazy` | Plugin status; `U` updates them |
| `:Mason` | Language servers and formatters |
| `:TSUpdate` | Update tree-sitter parsers |
| `:TSInstall <lang>` | Add a parser; unknown filetypes install one on the fly |
| `:LspStatus` | Which language servers are attached to this buffer |
| `:LspRestart` | Restart every language server and clear every warning |
| `:checkhealth vim.lsp` | Full LSP detail, including servers that failed to start |
| `:checkhealth` | Diagnose a broken setup |

`:LspRestart` is the replacement for `CocRestart`: it stops every language
server, throws away every diagnostic on screen, then starts the servers again
and re-runs the linters. Neovim's own `:lsp restart` is narrower -- it only
restarts the servers attached to the current buffer, and leaves the warnings
from pylint, ruff and markdownlint behind, which are usually the ones that
still look wrong.

A loose `.rs` file outside any Cargo project still gets hover, completion and
go-to-definition: the config points rust-analyzer at the `.rs` files in the
directory as standalone crates. Diagnostics are the exception, because those
come from `cargo check`, which needs a `Cargo.toml` or `rust-project.json`.

The gleam server has no equivalent. It is the gleam compiler, it only works
inside a project, and it gives nothing at all without a `gleam.toml` and
sources under `src/`.

`hardtime.nvim` is in `lua/plugins/editor.lua` but disabled. Set
`enabled = true` to turn it on.
