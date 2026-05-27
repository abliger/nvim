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

-- 异步下载安装 im-select
local function install_im_select()
  local bin_dir = vim.fn.expand("~/.local/bin")
  vim.fn.mkdir(bin_dir, "p")

  local arch = vim.trim(vim.fn.system("uname -m"))
  local url
  if arch == "arm64" then
    url = "https://raw.githubusercontent.com/daipeihust/im-select/master/macOS/out/apple/im-select"
  else
    url = "https://raw.githubusercontent.com/daipeihust/im-select/master/macOS/out/intel/im-select"
  end

  vim.notify("im-select 未找到，正在后台下载 (" .. arch .. ")...", vim.log.levels.INFO)

  local cmd = { "bash", "-c", string.format(
    "curl -fsSL -o %s %s && chmod +x %s",
    vim.fn.shellescape(im_select_path),
    vim.fn.shellescape(url),
    vim.fn.shellescape(im_select_path)
  )}

  local stderr = {}

  vim.fn.jobstart(cmd, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          vim.notify("im-select 下载失败: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
          return
        end
        if vim.fn.executable(im_select_path) ~= 1 then
          vim.notify("im-select 下载后仍无法执行", vim.log.levels.ERROR)
          return
        end
        vim.notify("im-select 安装成功: " .. im_select_path, vim.log.levels.INFO)
      end)
    end,
  })
end

-- 若未安装则启动后台下载
if not im_select_available() then
  install_im_select()
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

  -- 离开终端模式时切换到英文输入法
  autocmd("TermLeave", {
    group = augroup("ImSelectTermLeave", {}),
    pattern = "*",
    callback = function()
      local current = get_current_im()
      if current and current ~= "" then
        last_im = current
      end
      set_im(default_im)
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

-- 启动时若参数为目录，由 neo-tree 的 hijack_netrw_behavior 接管（见 plugins/ui.lua）

-- 项目根目录自动切换由 project.nvim 处理（tools.lua），此处不再重复配置
