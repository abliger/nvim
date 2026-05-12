-- ==========================================
-- TypeScript 文件类型特定设置
-- ==========================================

local opt_local = vim.opt_local

opt_local.tabstop = 2
opt_local.softtabstop = 2
opt_local.shiftwidth = 2
opt_local.expandtab = true
opt_local.textwidth = 120
opt_local.colorcolumn = "120"

-- 折叠由全局 options.lua 统一设置，此处不需要重复配置
