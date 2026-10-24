-- Collaboration and Unity integration.
return {
    -- Real-time collaborative editing
    {
        "teamtype/teamtype-nvim",
        lazy = false,
        keys = {
            {
                "<leader>ej",
                "<cmd>TeamtypeJumpToCursor<cr>",
                desc = "Teamtype: jump to cursor",
            },
            { "<leader>ef", "<cmd>TeamtypeFollow<cr>", desc = "Teamtype: follow" },
        },
    },

    -- nvim-unity-sync needs nvim-tree to hook file create/delete/rename events.
    -- nvim-tree is configured to leave netrw alone (`-` still opens netrw);
    -- use :NvimTreeToggle if you ever want the tree.
    {
        "nvim-tree/nvim-tree.lua",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            disable_netrw = false,
            hijack_netrw = false,
            hijack_directories = { enable = false },
        },
    },

    -- Keeps Unity's Assembly-CSharp.csproj in sync when .cs files change
    -- (:Ustatus, :Usync, :Uopen)
    {
        "apyra/nvim-unity-sync",
        lazy = false,
        dependencies = { "nvim-tree/nvim-tree.lua" },
        config = function()
            require("unity.plugin").setup()
        end,
    },
}
