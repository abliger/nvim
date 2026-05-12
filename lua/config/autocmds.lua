-- ==========================================
-- 自动命令
-- ==========================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ==========================================
-- 输入法自动切换（macOS）
-- ==========================================
local im_select_path = vim.fn.expand("~/.local/bin/im-select")
local default_im = "com.apple.keylayout.ABC"
local last_im = default_im

-- 检查 im-select 是否可用
local function im_select_available()
  return vim.fn.executable(im_select_path) == 1
end

-- 获取当前输入法
local function get_current_im()
  local output = vim.fn.system(im_select_path)
  return vim.trim(output)
end

-- 设置输入法
local function set_im(im_id)
  vim.fn.system(im_select_path .. " " .. im_id)
end

if im_select_available() then
  -- 离开插入模式时保存当前输入法并切换到英文
  autocmd("InsertLeave", {
    group = augroup("ImSelectLeave", {}),
    pattern = "*",
    callback = function()
      local current = get_current_im()
      if current and current ~= "" then
        last_im = current
      end
      set_im(default_im)
    end,
  })

  -- 进入插入模式时恢复上一次的输入法
  autocmd("InsertEnter", {
    group = augroup("ImSelectEnter", {}),
    pattern = "*",
    callback = function()
      if last_im and last_im ~= "" then
        set_im(last_im)
      end
    end,
  })
end

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

-- 启动时如果参数是目录，自动打开 neo-tree
autocmd("VimEnter", {
  group = augroup("NeoTreeDirOpen", {}),
  pattern = "*",
  once = true,
  callback = function()
    if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      -- 删除默认的空白缓冲区
      vim.schedule(function()
        local buf = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname == "" then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        -- 打开 neo-tree 并定位到该目录
        require("neo-tree.command").execute({
          dir = vim.fn.argv(0),
          toggle = false,
        })
      end)
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
