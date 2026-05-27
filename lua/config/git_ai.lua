local M = {}

local function get_config(key, default)
  local val = vim.g["git_ai_" .. key]
  if val ~= nil and val ~= "" then
    return val
  end
  return default
end

local function get_staged_diff()
  local diff = vim.fn.system("git diff --staged --no-color")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return diff
end

local function get_git_status()
  local status = vim.fn.system("git status --short")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return status
end

-- 调用 shell 脚本生成 commit message
local function call_ai_script(diff, status, callback)
  local provider = get_config("provider", "openai")
  local model = get_config("model", "")
  local ollama_url = get_config("ollama_url", "http://localhost:11434")
  local api_key = get_config("openai_api_key", os.getenv("OPENAI_API_KEY") or "")
  local api_base = get_config("openai_api_base", os.getenv("OPENAI_API_BASE") or "https://api.openai.com/v1")

  if provider ~= "ollama" and provider ~= "kimi" and api_key == "" then
    vim.schedule(function()
      vim.notify("未设置 OPENAI_API_KEY 环境变量或 g:git_ai_openai_api_key", vim.log.levels.ERROR)
    end)
    return
  end

  local script_path = vim.fn.stdpath("config") .. "/scripts/git-ai-commit.sh"

  local prompt = string.format(
    "当前变更文件：\n%s\n\ndiff：\n%s",
    status or "",
    diff
  )

  local env = vim.deepcopy(vim.uv.os_environ())
  env.GIT_AI_PROVIDER = provider
  env.GIT_AI_MODEL = model
  env.GIT_AI_OLLAMA_URL = ollama_url
  env.OPENAI_API_KEY = api_key
  env.OPENAI_API_BASE = api_base

  local output = {}
  local stderr = {}

  local job_id = vim.fn.jobstart({ "bash", script_path }, {
    stdin = "pipe",
    stdout_buffered = true,
    stderr_buffered = true,
    env = env,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(output, line)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stderr, line)
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          local err = table.concat(stderr, "\n")
          vim.notify("git-ai-commit.sh 失败: " .. err, vim.log.levels.ERROR)
          return
        end
        while #output > 0 and output[#output] == "" do
          table.remove(output)
        end
        local message = table.concat(output, "\n"):gsub("^%s*(.-)%s*$", "%1")
        if message == "" then
          vim.notify("AI 未返回有效提交信息", vim.log.levels.WARN)
          return
        end
        callback(message)
      end)
    end,
  })

  if job_id <= 0 then
    vim.notify("无法启动 git-ai-commit.sh", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, prompt)
  vim.fn.chanclose(job_id, "stdin")
end

-- 生成 commit message 并填入当前 buffer
function M.generate_and_insert()
  local diff = get_staged_diff()
  if not diff or diff == "" then
    vim.notify("没有暂存的变更（请先 git add）", vim.log.levels.WARN)
    return
  end

  local status = get_git_status() or ""

  if #diff > 8000 then
    diff = diff:sub(1, 8000) .. "\n... (diff 已截断)"
  end

  vim.notify("正在生成提交信息...", vim.log.levels.INFO)

  call_ai_script(diff, status, function(message)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.split(message, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.notify("提交信息已生成", vim.log.levels.INFO)
  end)
end

-- 生成 commit message 并复制到剪贴板
function M.generate_and_copy()
  local diff = get_staged_diff()
  if not diff or diff == "" then
    vim.notify("没有暂存的变更", vim.log.levels.WARN)
    return
  end

  local status = get_git_status() or ""

  if #diff > 8000 then
    diff = diff:sub(1, 8000) .. "\n... (diff 已截断)"
  end

  vim.notify("正在生成提交信息...", vim.log.levels.INFO)

  call_ai_script(diff, status, function(message)
    vim.fn.setreg("+", message)
    local first_line = message:match("^[^\n]+") or message
    vim.notify("提交信息已复制到剪贴板: " .. first_line, vim.log.levels.INFO)
  end)
end

return M
