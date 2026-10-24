-- Colourschemes. ColorMyPencils() in lua/config/functions.lua picks the active
-- one; codedark is the default.
return {
    { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
    {
        "tomasiser/vim-code-dark",
        lazy = false,
        priority = 1000,
        config = function()
            ColorMyPencils("codedark")
        end,
    },
}
