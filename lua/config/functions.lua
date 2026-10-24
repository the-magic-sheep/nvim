-- Global helper functions, callable with `:lua Name(...)`.

--- Switch colourscheme: `:lua ColorMyPencils("codedark")` (the default) or
--- `:lua ColorMyPencils("rose-pine")`.
function ColorMyPencils(color)
    color = color or "rose-pine"

    if color == "rose-pine" then
        vim.cmd.colorscheme("rose-pine")
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    elseif color == "codedark" then
        vim.g.codedark_italics = 1
        vim.g.codedark_transparent = 1
        vim.cmd.colorscheme("codedark")
    else
        vim.cmd.colorscheme(color)
    end
end

--- Clear (reset == 1: fully reset) the terminal in the current window.
function ClearTerm(reset)
    vim.opt_local.scrollback = 1

    vim.api.nvim_command("startinsert")
    if reset == 1 then
        vim.api.nvim_feedkeys("reset", "t", false)
    else
        vim.api.nvim_feedkeys("clear", "t", false)
    end
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<cr>", true, false, true),
        "t",
        true
    )

    vim.opt_local.scrollback = 10000
end

--- Sort Python imports (isort) in the current buffer.
function SortImports()
    if vim.bo.filetype == "python" then
        require("conform").format({ formatters = { "isort" }, timeout_ms = 5000 })
    end
end

--- Format the current buffer with the formatter configured in
--- lua/plugins/format.lua, falling back to the language server.
--- Python gets its imports sorted as well; Markdown is fixed with markdownlint.
function DoAutoFormat()
    require("conform").format({ lsp_format = "fallback", timeout_ms = 5000 })
end

--- Format every file under the current working directory, write them all,
--- close their buffers and return to the file explorer.
function FormatAll()
    local conform = require("conform")
    local paths =
        vim.split(vim.fn.glob(vim.fn.getcwd() .. "/**/*"), "\n", { trimempty = true })

    print("Visiting...")

    -- Each file is written straight after it is formatted, so that moving to
    -- the next one is never blocked by unsaved changes.
    local function save_current()
        if vim.bo.modified and vim.api.nvim_buf_get_name(0) ~= "" then
            pcall(vim.cmd, "silent write")
        end
    end

    save_current()

    for _, file in ipairs(paths) do
        if vim.fn.filereadable(file) == 1 then
            if pcall(vim.cmd.edit, vim.fn.fnameescape(file)) then
                if
                    conform.format({
                        lsp_format = "fallback",
                        timeout_ms = 5000,
                        quiet = true,
                    })
                then
                    print("formatted ", file)
                end
                save_current()
            end
        end
    end

    pcall(vim.cmd, "silent! bufdo bd")
    vim.cmd.Ex()
end
