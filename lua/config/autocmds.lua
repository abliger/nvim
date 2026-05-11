-- ==========================================
-- 自动命令
-- ==========================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 高亮复制的内容
autocmd("TextYankPost", {
  group = augroup("HighlightYank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- 回到上次编辑位置
autocmd("BufReadPost", {
  group = augroup("LastPosition", {}),
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 自动切换目录到项目根
autocmd("BufEnter", {
  group = augroup("AutoRoot", {}),
  pattern = "*",
  callback = function()
    local root = vim.fs.root(0, { ".git", "pom.xml", "package.json", "vite.config.ts", "vue.config.js" })
    if root then
      vim.cmd("silent! lcd " .. root)
    end
  end,
})
