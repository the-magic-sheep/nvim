-- Editing helpers: file marks, undo history, git, comments, terminal, ...

local harpoon_keys = {
    {
        "<leader>a",
        function()
            require("harpoon"):list():add()
        end,
        desc = "Harpoon: add file",
    },
    {
        "<C-e>",
        function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: quick menu",
    },
}
for i = 1, 5 do
    table.insert(harpoon_keys, {
        "<leader>" .. i,
        function()
            require("harpoon"):list():select(i)
        end,
        desc = "Harpoon: file " .. i,
    })
end

local toggleterm_keys = {
    {
        [[<C-\><C-\>]],
        "<cmd>ToggleTerm<cr>",
        mode = { "n", "t" },
        desc = "Toggle terminal",
    },
}
for i = 1, 9 do
    table.insert(toggleterm_keys, {
        ([[<C-\>%d]]):format(i),
        ("<cmd>ToggleTerm %d<cr>"):format(i),
        mode = { "n", "t" },
        desc = "Toggle terminal " .. i,
    })
end

return {
    -- Quick file marks
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = harpoon_keys,
        config = function()
            require("harpoon"):setup()
        end,
    },

    -- Undo history as a tree
    {
        "mbbill/undotree",
        cmd = "UndotreeToggle",
        keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" } },
    },

    -- Git
    {
        "tpope/vim-fugitive",
        lazy = false,
        keys = { { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" } },
    },

    -- gc / gb to toggle comments
    { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },

    -- Floating terminals: <C-\><C-\> toggles, <C-\>1 .. <C-\>9 pick a numbered one
    {
        "akinsho/toggleterm.nvim",
        cmd = { "ToggleTerm", "TermExec" },
        keys = toggleterm_keys,
        opts = {
            size = 20,
            hide_numbers = true,
            shade_filetypes = {},
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                },
            },
        },
    },

    -- File icons (used by telescope, nvim-tree)
    { "nvim-tree/nvim-web-devicons", lazy = true, opts = {} },

    -- :MarkdownPreview in the browser
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        -- Downloads the preview server binary into app/bin. Run as a shell
        -- command so that lazy.nvim waits for it to finish.
        build = "cd app && bash ./install.sh",
    },

    -- Habit trainer that blocks repeated hjkl etc. Off, as before; flip
    -- `enabled` to true to turn it on.
    {
        "m4xshen/hardtime.nvim",
        enabled = false,
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {},
    },
}
