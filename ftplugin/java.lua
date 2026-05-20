-- ==========================================
-- Java 文件类型特定设置
-- ==========================================

local opt_local = vim.opt_local

-- Java 使用 4 空格缩进（全局默认是 2）
opt_local.tabstop = 4
opt_local.softtabstop = 4
opt_local.shiftwidth = 4
opt_local.expandtab = true

-- 文本宽度与折叠由全局 options.lua 统一设置，此处无需重复
