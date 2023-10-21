local opt = vim.opt

opt.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20,a:Cursor/lCursor"
--opt.guicursor = "n-v-c-sm-i-ci-ve:block,r-cr-o:hor20,a:blinkoff400-blinkon250-Cursor/lCursor"

-- Numbering
opt.nu = true -- show numbered lines 
opt.relativenumber = true -- make line numbers relative to cursor posititon

-- Tabs + Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.wrap = false

-- Search
opt.incsearch = true
opt.hlsearch = false

opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.termguicolors = true
opt.colorcolumn = "80"
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.isfname:append("@-@")
opt.updatetime = 50

opt.errorbells = false
opt.encoding = 'UTF-8'

vim.api.nvim_set_option("clipboard","unnamedplus")

vim.g.netrw_bufsettings="noma nomod nonu nobl nowrap ro rnu"

vim.g.mapleader = " "
vim.g.maplocalleader = " "
