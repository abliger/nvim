-- ==========================================
-- 全局快捷键映射
-- ==========================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 普通模式 --

-- 更好的窗口导航
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- 调整窗口大小
map("n", "<C-Up>", ":resize -2<CR>", opts)
map("n", "<C-Down>", ":resize +2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- 缓冲区导航
map("n", "<S-l>", ":bnext<CR>", opts)
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", { desc = "关闭缓冲区" })

-- 取消搜索高亮
map("n", "<Esc>", ":noh<CR>", opts)

-- 保持光标居中滚动
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

-- 视觉模式 --

-- 移动选中文本
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- 保持复制内容（粘贴时不替换寄存器）
map("v", "p", '"_dP', opts)

-- 插入模式 --

-- 快速退出插入模式
map("i", "jk", "<Esc>", opts)
map("i", "kj", "<Esc>", opts)

-- 命令模式 --

-- 快速保存和退出
map("n", "<leader>w", ":w<CR>", { desc = "保存文件" })
map("n", "<leader>qq", ":q<CR>", { desc = "退出" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "强制退出全部" })

-- 快速编辑配置文件
map("n", "<leader>ev", ":e ~/.config/nvim/init.lua<CR>", { desc = "编辑配置" })

-- 终端模式 --

-- 按 Ctrl+Q 退出终端插入模式，回到普通模式（保留 <Esc> 给终端内程序使用）
map("t", "<C-q>", [[<C-\><C-n>]], { noremap = true, desc = "退出终端插入模式" })

-- 终端模式下直接切换窗口（先退出终端模式再切窗口）
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { noremap = true })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { noremap = true })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { noremap = true })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { noremap = true })
