-- Fuzzy finder.
return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-file-browser.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        cmd = "Telescope",
        keys = {
            {
                "<leader>pf",
                function()
                    require("telescope.builtin").find_files()
                end,
                desc = "Find files",
            },
            {
                "<C-p>",
                function()
                    require("telescope.builtin").git_files()
                end,
                desc = "Find git files",
            },
            {
                "<leader>ps",
                function()
                    require("telescope.builtin").grep_string({
                        search = vim.fn.input("Grep > "),
                    })
                end,
                desc = "Grep for a string",
            },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({})
            telescope.load_extension("fzf")
            telescope.load_extension("file_browser") -- :Telescope file_browser
        end,
    },
}
