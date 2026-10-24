-- Syntax highlighting via tree-sitter, and indentation for the filetypes
-- Neovim has no indent script for (swift, gleam, elixir, toml, ...).
--
-- This is the `main` branch of nvim-treesitter, a full rewrite: parsers are
-- installed with pinned revisions and matching query files, which is what
-- makes Swift work. Requires the tree-sitter CLI (>= 0.26) on PATH.
--   :TSInstall <lang>   install a parser
--   :TSUpdate           update every installed parser
--   :TSLog              see what went wrong during an install

local ensure_installed = {
    "bash",
    "c",
    "cpp",
    "c_sharp",
    "cmake",
    "css",
    "csv",
    "diff",
    "dockerfile",
    "elixir",
    "erlang",
    "gitcommit",
    "git_config",
    "git_rebase",
    "gitignore",
    "gleam",
    "html",
    "ini",
    "javascript",
    "json",
    "json5",
    "lua",
    "luadoc",
    "make",
    "markdown",
    "markdown_inline",
    "mermaid",
    "objc",
    "powershell",
    "printf",
    "prisma",
    "python",
    "query",
    "regex",
    "requirements",
    "rst",
    "rust",
    "sql",
    "ssh_config",
    "swift",
    "toml",
    "tsx",
    "typescript",
    "udev",
    "vim",
    "vimdoc",
    "xml",
    "yaml",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false, -- this plugin does not support lazy-loading
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup({})

            -- No-op for parsers that are already installed.
            ts.install(ensure_installed)

            -- Parsers not in the list are installed the first time a file of
            -- that type is opened, as `auto_install` used to do.
            local attempted = {}

            --- True when something already indents this filetype: an indent
            --- script Neovim ships, or an ftplugin that set one of the
            --- built-in indent engines. Asking about the script rather than
            --- the options keeps the answer the same whichever of the two
            --- FileType autocommands runs first.
            local function already_indented(buf, ft)
                return #vim.api.nvim_get_runtime_file(
                            "indent/" .. ft .. ".vim",
                            false
                        )
                        > 0
                    or #vim.api.nvim_get_runtime_file("indent/" .. ft .. ".lua", false) > 0
                    or vim.bo[buf].indentexpr ~= ""
                    or vim.bo[buf].cindent
                    or vim.bo[buf].lisp
            end

            local function start_treesitter(buf, lang)
                if not vim.api.nvim_buf_is_valid(buf) then
                    return
                end
                pcall(vim.treesitter.start, buf, lang)

                -- The indent scripts Neovim ships are better tuned than the
                -- tree-sitter queries, so they win; this only fills in where
                -- there is nothing at all. Swift, gleam, elixir and toml have
                -- no indent script, which leaves them with 'smartindent':
                -- there cc, o and = reuse the current line's indent instead
                -- of working out the expected one.
                local ok, query = pcall(vim.treesitter.query.get, lang, "indents")
                if ok and query and not already_indented(buf, vim.bo[buf].filetype) then
                    vim.bo[buf].indentexpr =
                        "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup(
                    "config.treesitter",
                    { clear = true }
                ),
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(args.match)
                    if not lang then
                        return
                    end

                    -- Parser already available: start straight away.
                    if vim.treesitter.language.add(lang) then
                        start_treesitter(args.buf, lang)
                        return
                    end

                    -- Otherwise try to install it once per session.
                    if
                        attempted[lang]
                        or not vim.tbl_contains(ts.get_available(), lang)
                    then
                        return
                    end
                    attempted[lang] = true
                    ts.install(lang):await(function(err)
                        if not err then
                            vim.schedule(function()
                                start_treesitter(args.buf, lang)
                            end)
                        end
                    end)
                end,
            })
        end,
    },
}
