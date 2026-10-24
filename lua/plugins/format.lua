-- Formatting (conform.nvim) and linting (nvim-lint).
-- Nothing runs on save: <leader>ff formats (DoAutoFormat), linters run when a
-- file is opened or written. Tools are installed by mason (lua/plugins/lsp.lua).
--
-- Python: a project carrying a ruff config uses ruff for formatting, import
-- sorting and linting. Everything else uses isort, black and pylint. Set
-- `vim.g.python_formatter` to "ruff" or "black" in a project's .nvim.lua to
-- decide explicitly; see :help exrc.

--- True when the buffer belongs to a project configured for ruff.
local function uses_ruff(bufnr)
    if vim.g.python_formatter == "ruff" then
        return true
    elseif vim.g.python_formatter == "black" then
        return false
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()

    if vim.fs.find({ "ruff.toml", ".ruff.toml" }, { path = dir, upward = true })[1] then
        return true
    end

    -- Otherwise look for a [tool.ruff] section in pyproject.toml.
    local pyproject = vim.fs.find("pyproject.toml", { path = dir, upward = true })[1]
    if pyproject then
        local ok, lines = pcall(vim.fn.readfile, pyproject)
        if ok then
            for _, line in ipairs(lines) do
                if line:match("^%s*%[tool%.ruff") then
                    return true
                end
            end
        end
    end
    return false
end

return {
    {
        "stevearc/conform.nvim",
        cmd = "ConformInfo",
        opts = {
            formatters_by_ft = {
                python = function(bufnr)
                    if uses_ruff(bufnr) then
                        return { "ruff_organize_imports", "ruff_format" }
                    end
                    return { "isort", "black" }
                end,
                lua = { "stylua" },
                markdown = { "markdownlint-cli2" },
                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
                yaml = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                -- Anything else (rust, c, swift, c#, elixir, ...) is formatted by its language server.
            },
            default_format_opts = { lsp_format = "fallback" },
        },
    },
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufNewFile", "BufWritePost" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                markdown = { "markdownlint-cli2" },
            }

            -- pylint and ruff come from the active Python environment rather
            -- than mason, so they can see the project's packages. Like the old
            -- coc setup, ./modules is added to pylint's import path.
            lint.linters.pylint.args = vim.list_extend(
                { "--init-hook", "import sys; sys.path.insert(0, './modules')" },
                lint.linters.pylint.args
            )

            --- The linters to run for a buffer.
            local function linters_for(bufnr)
                local ft = vim.bo[bufnr].filetype
                if ft == "python" then
                    return uses_ruff(bufnr) and { "ruff" } or { "pylint" }
                end
                return lint.linters_by_ft[ft] or {}
            end

            vim.api.nvim_create_autocmd(
                { "BufReadPost", "BufNewFile", "BufWritePost" },
                {
                    group = vim.api.nvim_create_augroup(
                        "config.lint",
                        { clear = true }
                    ),
                    callback = function(args)
                        -- Only run linters that are actually installed.
                        local names = vim.tbl_filter(function(name)
                            local linter = lint.linters[name]
                            if type(linter) == "function" then
                                linter = linter()
                            end
                            local cmd = linter
                                and (
                                    type(linter.cmd) == "function" and linter.cmd()
                                    or linter.cmd
                                )
                            return cmd ~= nil and vim.fn.executable(cmd) == 1
                        end, linters_for(args.buf))
                        if #names > 0 then
                            lint.try_lint(names)
                        end
                    end,
                }
            )

            -- Reports which formatters and linters this buffer would use.
            vim.api.nvim_create_user_command("LintInfo", function()
                local bufnr = vim.api.nvim_get_current_buf()
                local formatters = vim.tbl_map(function(f)
                    return f.name
                end, require("conform").list_formatters_to_run(bufnr))
                vim.notify(
                    ("filetype: %s\nformatters: %s\nlinters: %s"):format(
                        vim.bo[bufnr].filetype,
                        #formatters > 0 and table.concat(formatters, ", ")
                            or "none, LSP fallback",
                        #linters_for(bufnr) > 0
                                and table.concat(linters_for(bufnr), ", ")
                            or "none"
                    ),
                    vim.log.levels.INFO
                )
            end, { desc = "Show the formatters and linters for this buffer" })
        end,
    },
}
