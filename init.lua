-- ==========================================
-- Neovim 配置 - Java + Vue 全栈开发环境
-- 适用于 /Users/lvming/Downloads/project/
-- ==========================================

-- Leader 键必须在任何插件加载之前设置
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 加载基础配置
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- 加载 lazy.nvim 插件管理器
require("config.lazy")
