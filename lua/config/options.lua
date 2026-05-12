-- ==========================================
-- 基础选项设置
-- ==========================================

local opt = vim.opt
local g = vim.g

-- 编码
opt.fileencoding = "utf-8"

-- 将 Mason 的 bin 目录加入 PATH，让外部插件能找到 oxfmt/oxlint/prettier 等
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.stdpath("data") .. "/mason/bin"

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

-- Session 保存内容：包含分屏布局、窗口大小、空窗口、buffer 列表、terminal 等
opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal" }

-- 鼠标
opt.mouse = "a"

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
