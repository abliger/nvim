local Terminal = require("toggleterm.terminal").Terminal

local M = {}

-- 通用浮动终端配置
local function float_opts(overrides)
  return vim.tbl_extend("force", {
    direction = "float",
    close_on_exit = false,
    float_opts = { border = "curved" },
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    end,
  }, overrides or {})
end

-- Lazygit（缓存终端实例以支持 toggle）
M.lazygit = Terminal:new(float_opts({
  cmd = "lazygit",
  dir = "git_dir",
  float_opts = { border = "double" },
  on_close = function()
    vim.cmd("startinsert!")
  end,
}))

-- 按文件类型运行当前文件
M.runners = {
  python = "python3",
  javascript = "node",
  typescript = "npx ts-node",
  sh = "bash",
  lua = "lua",
  go = "go run",
  rust = "cargo run",
  java = function(filepath)
    local dir = vim.fn.fnamemodify(filepath, ":h")
    local class = vim.fn.fnamemodify(filepath, ":t:r")
    return string.format("cd %s && javac %s && java %s", vim.fn.shellescape(dir), vim.fn.shellescape(filepath), class)
  end,
}

function M.run_current_file()
  local ft = vim.bo.filetype
  local runner = M.runners[ft]
  if not runner then
    vim.notify("没有为文件类型 '" .. ft .. "' 配置运行命令", vim.log.levels.WARN)
    return
  end

  local filepath = vim.fn.expand("%:p")
  local cmd = type(runner) == "function" and runner(filepath) or (runner .. " " .. vim.fn.shellescape(filepath))

  Terminal:new(float_opts({ cmd = cmd })):open()
end

-- 运行自定义命令
function M.run_custom_command()
  vim.ui.input({ prompt = "Run: " }, function(input)
    if not input or input == "" then
      return
    end
    Terminal:new(float_opts({ cmd = input })):open()
  end)
end

return M
