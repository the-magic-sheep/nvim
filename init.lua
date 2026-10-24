-- Entry point. Editor settings live in lua/config/, plugins in lua/plugins/
-- (one file per group, managed by lazy.nvim: run :Lazy to see them).

-- The leader key must be set before plugins load, or their keymaps would
-- bind to the default "\" leader.
vim.g.mapleader = " "

require("config.options")
require("config.keymaps")
require("config.functions")
require("config.autocmds")
require("config.lazy")
