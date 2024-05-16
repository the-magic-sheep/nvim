local toggleterm = require("toggleterm")

toggleterm.setup({
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
})

vim.keymap.set('n', "<C-\\><C-\\>", "<cmd>ToggleTerm<CR>")
vim.keymap.set('t', "<C-\\><C-\\>", "<cmd>ToggleTerm<CR>")
vim.keymap.set('n', "<C-\\>1", "<cmd>ToggleTerm 1<CR>")
vim.keymap.set('t', "<C-\\>1", "<cmd>ToggleTerm 1<CR>")
vim.keymap.set('n', "<C-\\>2", "<cmd>ToggleTerm 2<CR>")
vim.keymap.set('t', "<C-\\>2", "<cmd>ToggleTerm 2<CR>")
vim.keymap.set('n', "<C-\\>3", "<cmd>ToggleTerm 3<CR>")
vim.keymap.set('t', "<C-\\>3", "<cmd>ToggleTerm 3<CR>")
vim.keymap.set('n', "<C-\\>4", "<cmd>ToggleTerm 4<CR>")
vim.keymap.set('t', "<C-\\>4", "<cmd>ToggleTerm 4<CR>")
vim.keymap.set('n', "<C-\\>5", "<cmd>ToggleTerm 5<CR>")
vim.keymap.set('t', "<C-\\>5", "<cmd>ToggleTerm 5<CR>")
vim.keymap.set('n', "<C-\\>6", "<cmd>ToggleTerm 6<CR>")
vim.keymap.set('t', "<C-\\>6", "<cmd>ToggleTerm 6<CR>")
vim.keymap.set('n', "<C-\\>7", "<cmd>ToggleTerm 7<CR>")
vim.keymap.set('t', "<C-\\>7", "<cmd>ToggleTerm 7<CR>")
vim.keymap.set('n', "<C-\\>8", "<cmd>ToggleTerm 8<CR>")
vim.keymap.set('t', "<C-\\>8", "<cmd>ToggleTerm 8<CR>")
vim.keymap.set('n', "<C-\\>9", "<cmd>ToggleTerm 9<CR>")
vim.keymap.set('t', "<C-\\>9", "<cmd>ToggleTerm 9<CR>")
