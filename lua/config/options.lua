-- Editor options.
local opt = vim.opt

opt.guicursor = ""

opt.number = true
opt.relativenumber = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.smartindent = true

opt.wrap = false

opt.swapfile = false
opt.backup = false
opt.backupcopy = "yes" -- write files in place so file watchers see the change
opt.writebackup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.hlsearch = false
opt.incsearch = true

opt.termguicolors = true

opt.scrolloff = 8

opt.signcolumn = "yes"

opt.updatetime = 50

opt.colorcolumn = "88"

opt.splitbelow = true
opt.splitright = true

opt.virtualedit = "onemore"

-- Rounded border on floating windows (hover docs, diagnostics, ...).
opt.winborder = "rounded"

-- Load project-local config from .nvim.lua in the working directory and its
-- parents. Each file must be trusted once with :trust before it runs.
vim.o.exrc = true

-- Neovim inherits PATH from whatever launched it, which is not always the
-- shell that sourced ~/.bashrc. Language servers live in some of these
-- directories, so put them back when they exist.
local toolchain_dirs = {
    vim.fn.expand("~/.cargo/bin"), -- cargo, rust-analyzer, gleam
    vim.fn.expand("~/.local/share/swiftly/bin"), -- sourcekit-lsp, swift
    vim.fn.expand("~/.local/bin"), -- tree-sitter
}
local path = vim.split(vim.env.PATH or "", ":", { trimempty = true })
local prefix = {}
for _, dir in ipairs(toolchain_dirs) do
    if vim.fn.isdirectory(dir) == 1 and not vim.tbl_contains(path, dir) then
        prefix[#prefix + 1] = dir
    end
end
if #prefix > 0 then
    vim.env.PATH = table.concat(prefix, ":") .. ":" .. vim.env.PATH
end

-- Only the Python 3 provider is used (by rplugin/python3/). Disabling the
-- others keeps startup quick and :checkhealth quiet.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
