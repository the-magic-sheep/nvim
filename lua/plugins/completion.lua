-- Autocompletion (blink.cmp). Keys match the old coc setup:
--   <C-j> / <C-k>   next / previous item (move the cursor when the menu is closed)
--   <C-Space>       accept the selected item (types a space when the menu is closed)
--   <C-n> / <C-p>   jump to the next / previous snippet placeholder
--   <C-y> accepts too, <C-e> closes the menu.
return {
    {
        "saghen/blink.cmp",
        version = "1.*", -- release with a prebuilt fuzzy matcher
        lazy = false,
        dependencies = { "folke/lazydev.nvim" },
        opts = {
            keymap = {
                preset = "default",
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
                -- Some terminals send <C-@> for Ctrl-Space, so bind both.
                ["<C-space>"] = {
                    "accept",
                    function()
                        vim.api.nvim_feedkeys(" ", "n", false)
                        return true
                    end,
                },
                ["<C-@>"] = {
                    "accept",
                    function()
                        vim.api.nvim_feedkeys(" ", "n", false)
                        return true
                    end,
                },
                ["<C-n>"] = { "snippet_forward", "fallback" },
                ["<C-p>"] = { "snippet_backward", "fallback" },
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
            },
            signature = { enabled = true },
            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" },
    },
}
