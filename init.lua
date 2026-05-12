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

-- nvim 不带参数启动时，自动弹出 session 选择器
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() == 0 then
      vim.defer_fn(function()
        local ok, auto_session = pcall(require, "auto-session")
        if ok then
          auto_session.search()
        end
      end, 150)
    end
  end,
})
