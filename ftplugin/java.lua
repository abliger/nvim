-- ==========================================
-- Java 文件类型特定设置
-- ==========================================

local opt_local = vim.opt_local

-- Java 缩进 (4 空格)
opt_local.tabstop = 4
opt_local.softtabstop = 4
opt_local.shiftwidth = 4
opt_local.expandtab = true

-- 文本宽度
opt_local.textwidth = 120
opt_local.colorcolumn = "120"

-- 折叠由全局 options.lua 统一设置，此处不需要重复配置
