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
    -- 排除特殊文件类型，避免干扰 neo-tree 等插件的缓冲区操作
    local exclude_fts = { "neo-tree", "NvimTree", "lazy", "mason", "TelescopePrompt", "nofile", "prompt" }
    local current_ft = vim.bo.filetype
    for _, ft in ipairs(exclude_fts) do
      if current_ft == ft then
        return
      end
    end

    -- 排除无名称缓冲区和特殊缓冲区
    local bufname = vim.api.nvim_buf_get_name(0)
    local buftype = vim.bo.buftype
    if buftype ~= "" or bufname == "" then
      return
    end

    local root = vim.fs.root(0, { ".git", "pom.xml", "package.json", "vite.config.ts", "vue.config.js", "init.lua" })
    if root then
      vim.cmd("silent! lcd " .. root)
    end
  end,
})
