-- Language servers, replacing coc.nvim with Neovim's built-in LSP client.
--
-- mason installs the servers and tools that aren't already on the system;
-- run `:Mason` to see them, `:checkhealth lsp` to see what is attached.
--
-- Buffer-local keymaps (only where a server is attached):
--   gd          go to definition
--   <leader>gd  go to definition in a vertical split
--   gy          go to type definition
--   <C-n>       hover documentation
--   grn         rename          gra  code action
--   grr         references      gri  implementation
--
-- Diagnostics appear in a floating window when the cursor rests; <leader>cd
-- switches between "under the cursor" and "anywhere on this line".
--
-- :LspStatus   which servers are attached here
-- :LspRestart  the old CocRestart: restart every server, clear every warning

-- Servers installed by mason. Names are nvim-lspconfig names.
local mason_servers = {
    "lua_ls",
    "pyright",
    "clangd",
    "ts_ls",
    "html",
    "cssls",
    "jsonls",
    "yamlls",
    "lemminx", -- xml
    "bashls",
    "marksman", -- markdown
    "omnisharp", -- c#
}

-- Servers that come with their own toolchain, so mason must not manage them.
-- Neovim checks that the command exists each time a matching file is opened
-- and quietly skips the server when it is missing, so these are always
-- enabled: installing the toolchain later is enough to make one work.
local external_servers = {
    "rust_analyzer", -- rustup component add rust-analyzer
    "sourcekit", -- swiftly / Xcode
    "gleam", -- the gleam compiler
    "elixirls", -- ~/.elixir-ls (cmd set below)
    "nim_langserver", -- nimlangserver
}

-- Tools that aren't language servers (formatters, linters).
local mason_tools = {
    "black",
    "isort",
    "stylua",
    "prettier",
    "markdownlint-cli2",
}

--- Go to definition, opening the result in a vertical split.
--- If the definition is where the cursor already is, nothing is split.
local function definition_in_split()
    vim.lsp.buf.definition({
        on_list = function(result)
            local items = result.items or {}
            if #items == 0 then
                vim.notify("No definition found", vim.log.levels.WARN)
                return
            end
            if #items > 1 then
                -- Ambiguous: show the candidates instead of guessing.
                vim.fn.setqflist({}, " ", result)
                vim.cmd("copen")
                return
            end

            local item = items[1]
            local target = vim.fn.fnamemodify(item.filename, ":p")
            local cursor = vim.api.nvim_win_get_cursor(0)
            if
                target == vim.api.nvim_buf_get_name(0)
                and cursor[1] == item.lnum
                and cursor[2] + 1 == item.col
            then
                return -- already at the definition
            end

            vim.cmd("vsplit")
            vim.cmd.edit(vim.fn.fnameescape(target))
            pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, item.col - 1 })
            vim.cmd("normal! zz")
        end,
    })
end

--- Show hover documentation, or close it if it is already showing.
--- The float carries a window variable named after its focus id, so this
--- finds the hover window without touching the diagnostic float, which uses
--- "line" or "cursor" instead.
local function toggle_hover()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if pcall(vim.api.nvim_win_get_var, win, "textDocument/hover") then
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    -- focus = false keeps the cursor in the code. Neovim's own K opens the
    -- same float with focus, for scrolling through long documentation.
    vim.lsp.buf.hover({ focus = false })
end

local function on_attach(args)
    local opts = { buffer = args.buf, silent = true }
    local map = vim.keymap.set

    map(
        "n",
        "gd",
        vim.lsp.buf.definition,
        vim.tbl_extend("force", opts, { desc = "Go to definition" })
    )
    map(
        "n",
        "<leader>gd",
        definition_in_split,
        vim.tbl_extend("force", opts, { desc = "Definition in split" })
    )
    map(
        "n",
        "gy",
        vim.lsp.buf.type_definition,
        vim.tbl_extend("force", opts, { desc = "Go to type definition" })
    )
    map(
        "n",
        "<C-n>",
        toggle_hover,
        vim.tbl_extend("force", opts, { desc = "Hover documentation (toggle)" })
    )

    -- Neovim already provides grn (rename), gra (code action), grr
    -- (references), gri (implementation) and grt (type definition).
end

return {
    -- Installs language servers and tools into ~/.local/share/nvim/mason
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" },
        opts = {},
    },

    -- Lua language server that understands the Neovim API
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
        },
    },

    -- JSON/YAML schemas, replacing what coc-json and coc-yaml provided
    { "b0o/SchemaStore.nvim", lazy = true, version = false },

    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        -- Defined at startup so it works even before a server has loaded.
        init = function()
            vim.api.nvim_create_user_command("LspStatus", function()
                local lines = {}
                local here = vim.lsp.get_clients({ bufnr = 0 })

                if #here == 0 then
                    local ft = vim.bo.filetype
                    lines[#lines + 1] = ("No server attached (filetype: %s)"):format(
                        ft == "" and "none" or ft
                    )
                else
                    lines[#lines + 1] = "Attached to this buffer:"
                    for _, c in ipairs(here) do
                        lines[#lines + 1] = ("  %s -- root: %s"):format(
                            c.name,
                            c.config.root_dir or "none, single-file mode"
                        )
                    end
                end

                local attached = {}
                for _, c in ipairs(here) do
                    attached[c.id] = true
                end
                local elsewhere = {}
                for _, c in ipairs(vim.lsp.get_clients()) do
                    if not attached[c.id] then
                        elsewhere[#elsewhere + 1] = c.name
                    end
                end
                if #elsewhere > 0 then
                    lines[#lines + 1] = "Running for other buffers: "
                        .. table.concat(elsewhere, ", ")
                end

                lines[#lines + 1] = "Log: " .. vim.lsp.log.get_filename()
                vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
            end, { desc = "Show the language servers for this buffer" })

            -- What CocRestart used to do, for when something has gone odd:
            -- every server is restarted from scratch and every diagnostic on
            -- screen is thrown away. `:lsp restart` (built into Neovim) only
            -- restarts the servers attached to the current buffer, and leaves
            -- the diagnostics from nvim-lint's linters -- pylint, ruff,
            -- markdownlint -- in place, which is usually what still looks
            -- wrong afterwards.
            vim.api.nvim_create_user_command("LspRestart", function()
                local names, seen = {}, {}
                for _, client in ipairs(vim.lsp.get_clients()) do
                    if not seen[client.name] then
                        seen[client.name] = true
                        names[#names + 1] = client.name
                    end
                    -- Graceful, so the server exits 0 instead of being
                    -- reported as having crashed. A server that ignores the
                    -- request is killed after its exit_timeout.
                    client:stop()
                end

                -- Everything on screen is stale now: the LSP diagnostics
                -- belong to servers that are going away, the linters' belong
                -- to a run that may have failed. Both come back below.
                vim.diagnostic.reset()

                -- Stopping is asynchronous, and a server that is still
                -- shutting down would be reused instead of restarted.
                local stopped = vim.wait(5000, function()
                    return #vim.lsp.get_clients() == 0
                end, 50)

                -- This FileType autocommand is how vim.lsp.enable() attaches
                -- a server to a buffer in the first place.
                vim.cmd.doautoall("nvim.lsp.enable FileType")

                -- Linters only run on read and write, so without this the
                -- cleared warnings would not reappear until the next save.
                -- The group is the one in lua/plugins/format.lua.
                pcall(vim.cmd.doautoall, "config.lint BufWritePost")

                local msg
                if not stopped then
                    msg = "Some servers did not stop; see :LspStatus"
                elseif #names == 0 then
                    msg = "No server was running. Diagnostics cleared."
                else
                    msg = "Restarted: " .. table.concat(names, ", ")
                end
                vim.notify(msg, vim.log.levels.INFO)
            end, {
                desc = "Restart every language server and clear all diagnostics",
            })
        end,
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "mason-org/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "b0o/SchemaStore.nvim",
        },
        config = function()
            -- Per-server settings. Everything else uses the defaults that
            -- nvim-lspconfig ships.
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        format = { enable = false }, -- stylua does this
                        workspace = { checkThirdParty = false },
                    },
                },
            })

            vim.lsp.config("pyright", {
                settings = {
                    python = {
                        pythonPath = "python3",
                        analysis = {
                            typeCheckingMode = "basic",
                            diagnosticMode = "openFilesOnly",
                            extraPaths = { "./modules" },
                        },
                    },
                },
            })

            -- rust-analyzer normally refuses to work outside a Cargo project.
            -- For loose .rs files it is pointed at them explicitly, which
            -- gives hover, completion and go-to-definition. Diagnostics still
            -- need a real project, because those come from `cargo check`.
            local rust_defaults = vim.lsp.config.rust_analyzer
            local rust_root_dir = rust_defaults.root_dir
            local rust_before_init = rust_defaults.before_init

            vim.lsp.config("rust_analyzer", {
                settings = {
                    ["rust-analyzer"] = {
                        rustfmt = { extraArgs = { "--config", "max_width=80" } },
                    },
                },
                root_dir = function(bufnr, on_dir)
                    local fname = vim.api.nvim_buf_get_name(bufnr)
                    -- A real project: let nvim-lspconfig work the root out,
                    -- including cargo workspaces.
                    if vim.fs.root(fname, { "Cargo.toml", "rust-project.json" }) then
                        return rust_root_dir(bufnr, on_dir)
                    end
                    -- Otherwise the file's own directory is the root.
                    on_dir(vim.fs.dirname(fname))
                end,
                before_init = function(params, config)
                    local root = config.root_dir
                    local in_project = root
                        and vim.fs.root(root, { "Cargo.toml", "rust-project.json" })
                    if root and not in_project then
                        local loose = vim.fn.glob(root .. "/*.rs", false, true)
                        if #loose > 0 then
                            config.settings = config.settings or {}
                            local ra = config.settings["rust-analyzer"] or {}
                            ra.linkedProjects = loose
                            config.settings["rust-analyzer"] = ra
                        end
                    end
                    -- Hands the settings to the server as initializationOptions.
                    if rust_before_init then
                        rust_before_init(params, config)
                    end
                end,
            })

            vim.lsp.config("jsonls", {
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = { enable = true },
                    },
                },
            })

            vim.lsp.config("yamlls", {
                settings = {
                    yaml = {
                        schemaStore = { enable = false, url = "" },
                        schemas = require("schemastore").yaml.schemas(),
                    },
                },
            })

            vim.lsp.config("elixirls", {
                cmd = { vim.fn.expand("~/.elixir-ls/release/language_server.sh") },
            })

            -- sourcekit-lsp also claims C/C++/Objective-C; leave those to clangd.
            vim.lsp.config("sourcekit", {
                filetypes = { "swift" },
                capabilities = {
                    workspace = {
                        didChangeWatchedFiles = { dynamicRegistration = true },
                    },
                },
            })

            require("mason-tool-installer").setup({
                ensure_installed = vim.list_extend(
                    vim.deepcopy(mason_tools),
                    mason_servers
                ),
                run_on_start = true,
                auto_update = false,
            })

            -- mason-lspconfig enables each mason-installed server for us.
            -- stylua is excluded because it shares its name with an
            -- lspconfig entry; it is a formatter, and conform.nvim runs it.
            require("mason-lspconfig").setup({
                ensure_installed = {},
                automatic_enable = { exclude = { "stylua" } },
            })

            -- Enabled one at a time so that a single bad config cannot stop
            -- the rest from being enabled.
            for _, server in ipairs(external_servers) do
                pcall(vim.lsp.enable, server)
            end

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup(
                    "config.lsp_attach",
                    { clear = true }
                ),
                callback = on_attach,
            })
        end,
    },
}
