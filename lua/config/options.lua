-- ==========================================
-- 基础选项设置
-- ==========================================

local opt = vim.opt
local g = vim.g

-- 编码
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- 行号
opt.number = true
opt.relativenumber = true

-- 缩进
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- 换行
opt.wrap = false

-- 搜索
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- 外观
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "120"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- 文件
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undodir")

-- 剪贴板
opt.clipboard = "unnamedplus"

-- 分割窗口
opt.splitright = true
opt.splitbelow = true

-- 补全
opt.completeopt = { "menu", "menuone", "noselect" }

-- 性能
opt.updatetime = 300
opt.timeoutlen = 500

-- 折叠 (treesitter v1.0+)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false

-- 禁用内置 netrw（使用 neo-tree）
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
