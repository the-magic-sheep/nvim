-- General keymaps.
-- Plugin keymaps live next to their plugin in lua/plugins/*.lua. LSP keymaps
-- (gd, gy, <C-n>, <leader>gd) are in lua/plugins/lsp.lua and only apply in
-- buffers with a language server attached.
local map = vim.keymap.set

-- File explorer (netrw)
map("n", "<leader>pv", vim.cmd.Ex, { desc = "File explorer" })
map("n", "-", vim.cmd.Ex, { desc = "File explorer" })

-- Format the buffer (see DoAutoFormat in lua/config/functions.lua)
map("n", "<leader>ff", function()
    DoAutoFormat()
end, { desc = "Format buffer" })

-- Diagnostics popup: toggle between "under the cursor" and "anywhere on the line"
map("n", "<leader>cd", function()
    ToggleLineDiagnostics()
end, { desc = "Toggle line diagnostics" })

-- Diagnostics popup, with the cursor inside it: scroll it, yank from it,
-- `q` or move away to close
map("n", "<leader>cf", function()
    FocusDiagnostics()
end, { desc = "Focus diagnostics popup" })

map("n", "<leader>h", vim.cmd.noh, { desc = "Clear search highlight" })

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep the cursor in place when joining lines, centred when jumping
map("n", "J", "mzJ`z")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Paste over a selection without clobbering the register
map("x", "<leader>p", '"_dP')

-- System clipboard
map({ "n", "v" }, "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')

-- Delete without touching registers
map({ "n", "v" }, "<leader>d", '"_d')

-- Empty line below/above without leaving normal mode
map("n", "<leader>o", 'o<Esc>0"_D')
map("n", "<leader>O", 'O<Esc>0"_D')

map("i", "<C-c>", "<Esc>")

-- Replace the word under the cursor across the file
map("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Faster movement
map("n", "<C-j>", "5jzz")
map("n", "<C-k>", "5kzz")
map("n", "<C-h>", "5h")
map("n", "<C-l>", "5l")

-- Cursor movement in insert mode. When the completion menu is open,
-- <C-j>/<C-k> move through it instead (lua/plugins/completion.lua).
map("i", "<C-j>", "<C-o>j")
map("i", "<C-k>", "<C-o>k")
map("i", "<C-h>", "<C-o>h")
map("i", "<C-l>", "<C-o>l")

map("n", "<leader>v", vim.cmd.vs, { desc = "Vertical split" })

map("n", "$", "$l")

-- Clear the terminal (see ClearTerm in lua/config/functions.lua)
map("t", "<C-l><C-l>", [[<C-\><C-N>:lua ClearTerm(0)<CR>]])

-- Never suspend nvim by accident
map({ "n", "i", "v" }, "<C-z>", "<Nop>")
