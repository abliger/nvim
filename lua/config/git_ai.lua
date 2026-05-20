local M = {}

local function get_env(var, default)
  return os.getenv(var) or default
end

-- 获取 staged diff
local function get_staged_diff()
  local diff = vim.fn.system("git diff --staged --no-color")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return diff
end

-- 获取 git status 摘要
local function get_git_status()
  local status = vim.fn.system("git status --short")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return status
end

-- 调用 OpenAI 兼容格式的 AI API
local function call_ai(prompt, callback)
  local api_key = get_env("OPENAI_API_KEY", "")
  local api_base = get_env("OPENAI_API_BASE", "https://api.openai.com/v1")

  if api_key == "" then
    vim.schedule(function()
      vim.notify("未设置 OPENAI_API_KEY 环境变量", vim.log.levels.ERROR)
    end)
    return
  end

  local model = get_env("OPENAI_MODEL", "gpt-3.5-turbo")

  local body = vim.fn.json_encode({
    model = model,
    messages = {
      {
        role = "system",
        content = "你是一个专业的代码审查助手，擅长根据代码变更生成规范的 git commit message。",
      },
      { role = "user", content = prompt },
    },
    temperature = 0.3,
    max_tokens = 300,
  })

  local cmd = string.format(
    'curl -s -L %s/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d %s',
    api_base,
    api_key,
    vim.fn.shellescape(body)
  )

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 or (data[1] == "" and #data == 1) then
        return
      end
      local response = table.concat(data, "\n")
      local ok, decoded = pcall(vim.fn.json_decode, response)
      if not ok or not decoded then
        vim.schedule(function()
          vim.notify("AI API 响应解析失败", vim.log.levels.ERROR)
        end)
        return
      end

      if decoded.error then
        local err_msg = type(decoded.error) == "table" and (decoded.error.message or vim.inspect(decoded.error)) or tostring(decoded.error)
        vim.schedule(function()
          vim.notify("AI API 错误: " .. err_msg, vim.log.levels.ERROR)
        end)
        return
      end

      local message = decoded.choices
        and decoded.choices[1]
        and decoded.choices[1].message
        and decoded.choices[1].message.content
      if message then
        vim.schedule(function()
          callback(message:gsub("^%s*(.-)%s*$", "%1"))
        end)
      else
        vim.schedule(function()
          vim.notify("AI API 未返回有效内容", vim.log.levels.WARN)
        end)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.schedule(function()
          vim.notify("AI API 错误: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

-- 构建 prompt
local function build_prompt(diff, status)
  return string.format(
    [[请根据以下 git diff 生成一个简洁、规范的提交信息（commit message）。

要求：
1. 使用 conventional commit 格式，如：
   - feat: 新增功能
   - fix: 修复 bug
   - docs: 文档更新
   - refactor: 重构代码
   - chore: 杂项/构建/工具更新
   - test: 测试相关
   - style: 代码格式
2. 第一行是标题，不超过 50 个字符
3. 如果变更有意义，可以添加空行后的详细描述（每行不超过 72 字符）
4. 只返回提交信息文本，不要任何解释或 markdown 格式

当前变更文件：
%s

diff：
%s]],
    status or "",
    diff
  )
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

  local prompt = build_prompt(diff, status)
  vim.notify("正在生成提交信息...", vim.log.levels.INFO)

  call_ai(prompt, function(message)
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

  local prompt = build_prompt(diff, status)
  vim.notify("正在生成提交信息...", vim.log.levels.INFO)

  call_ai(prompt, function(message)
    vim.fn.setreg("+", message)
    local first_line = message:match("^[^\n]+") or message
    vim.notify("提交信息已复制到剪贴板: " .. first_line, vim.log.levels.INFO)
  end)
end

return M
