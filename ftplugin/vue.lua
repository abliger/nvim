-- ==========================================
-- Vue 文件类型特定设置
-- ==========================================

local opt_local = vim.opt_local

-- Vue 缩进 (2 空格)
opt_local.tabstop = 2
opt_local.softtabstop = 2
opt_local.shiftwidth = 2
opt_local.expandtab = true

-- 文本宽度
opt_local.textwidth = 120
opt_local.colorcolumn = "120"

-- 折叠
opt_local.foldmethod = "expr"
opt_local.foldexpr = "nvim_treesitter#foldexpr()"
opt_local.foldenable = false
