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

ColorMyPencils("codedark")
