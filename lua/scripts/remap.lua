vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "-", vim.cmd.Ex)

vim.keymap.set("n", "<leader>ff", function()
    DoAutoFormat();
end)


vim.keymap.set("n", "<leader>gd", function()
    local old_cur_pos = vim.fn.getcurpos()
    vim.cmd.call("CocAction('jumpDefinition')")
    if not Equals(old_cur_pos, vim.fn.getcurpos(), false) then
        vim.cmd('vsplit')
        vim.api.nvim_input("<C-w>w")
        vim.api.nvim_input("<C-O>")
        vim.api.nvim_input("<C-w>w")
    end
end)

vim.keymap.set("n", "<C-@>", "<C-Space>")

vim.keymap.set("n", "<leader>h", vim.cmd.noh)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", "\"_dP")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")


vim.keymap.set("n", "<leader>o", "o<Esc>0\"_D")
vim.keymap.set("n", "<leader>O", "O<Esc>0\"_D")

vim.keymap.set("i", "<C-c>", "<Esc>")


vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

vim.keymap.set("n", "<C-J>", "5jzz")
vim.keymap.set("n", "<C-K>", "5kzz")

vim.keymap.set("i", "<C-J>", "<C-O>j")
vim.keymap.set("i", "<C-K>", "<C-O>k")
vim.keymap.set("i", "<C-H>", "<C-O>h")
vim.keymap.set("i", "<C-L>", "<C-O>l")

vim.keymap.set("n", "<C-h>", "5h")
vim.keymap.set("n", "<C-l>", "5l")

vim.keymap.set("n", "<leader>v", vim.cmd.vs)
