-- ==========================================
-- 注释/字符串翻译（中文）
-- 使用百度翻译 API（需设置 BAIDU_APPID / BAIDU_KEY）
-- 注释识别基于 noir4y/comment-translate.nvim
-- ==========================================

local function urlencode(str)
  return str:gsub("([^A-Za-z0-9_%-%.%~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- 使用系统 md5 命令计算百度翻译签名（macOS 兼容）
local function md5(str)
  local output = vim.fn.system("md5 -s " .. vim.fn.shellescape(str))
  return output:match("= (%x+)") or ""
end

local function baidu_translate(text, target_lang, callback)
  local appid = vim.env.BAIDU_APPID
  local key = vim.env.BAIDU_KEY

  if not appid or appid == "" or not key or key == "" then
    vim.notify(
      "请设置环境变量 BAIDU_APPID 和 BAIDU_KEY 以使用百度翻译",
      vim.log.levels.ERROR
    )
    callback(nil)
    return
  end

  local salt = tostring(os.time()) .. tostring(math.random(1000, 9999))
  local sign = md5(appid .. text .. salt .. key)

  local to_lang = "zh"
  if target_lang == "en" then
    to_lang = "en"
  end

  local body = string.format(
    "q=%s&from=auto&to=%s&appid=%s&salt=%s&sign=%s",
    urlencode(text),
    to_lang,
    urlencode(appid),
    salt,
    sign
  )

  vim.system({
    "curl",
    "-sL",
    "--max-time",
    "10",
    "-X",
    "POST",
    "https://fanyi-api.baidu.com/api/trans/vip/translate",
    "-H",
    "Content-Type: application/x-www-form-urlencoded",
    "--data",
    body,
  }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify("百度翻译请求失败: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        callback(nil)
        return
      end

      local ok, json = pcall(vim.fn.json_decode, obj.stdout)
      if not ok or not json then
        vim.notify("百度翻译响应解析失败: " .. obj.stdout, vim.log.levels.ERROR)
        callback(nil)
        return
      end

      if json.error_code then
        vim.notify(
          string.format("百度翻译失败 [%s]: %s", json.error_code, json.error_msg or "未知错误"),
          vim.log.levels.ERROR
        )
        callback(nil)
        return
      end

      if not json.trans_result or #json.trans_result == 0 then
        vim.notify("百度翻译返回空结果", vim.log.levels.ERROR)
        callback(nil)
        return
      end

      local parts = {}
      for _, item in ipairs(json.trans_result) do
        table.insert(parts, item.dst)
      end
      callback(table.concat(parts, "\n"))
    end)
  end)
end

local TARGET_LANGUAGE = "zh-CN"

local function smart_hover()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 1. 若光标位于注释或字符串上，则翻译并同时显示原文与译文
  local ok_parser, parser = pcall(require, "comment-translate.parser")
  if ok_parser then
    local text = parser.get_text_at_cursor(bufnr)
    if text and text ~= "" then
      local ok_ui, hover_ui = pcall(require, "comment-translate.ui.hover")
      if not ok_ui then
        vim.notify("comment-translate.ui.hover 加载失败", vim.log.levels.ERROR)
        return
      end

      vim.notify("正在翻译: " .. text:sub(1, 40) .. (#text > 40 and "..." or ""), vim.log.levels.INFO)
      baidu_translate(text, TARGET_LANGUAGE, function(result)
        if not result or result == "" then
          vim.notify("翻译未返回结果，请检查 BAIDU_APPID / BAIDU_KEY", vim.log.levels.ERROR)
          return
        end

        local lines = {
          "# 原文",
          "",
          "```text",
          text,
          "```",
          "",
          "# 译文（" .. TARGET_LANGUAGE .. "）",
          "",
          result,
        }
        hover_ui.show(table.concat(lines, "\n"))
      end)
      return
    else
      vim.notify("光标未在注释或字符串上，回退到 LSP hover", vim.log.levels.INFO)
    end
  else
    vim.notify("comment-translate.parser 加载失败", vim.log.levels.ERROR)
  end

  -- 2. 否则回退到 LSP hover（若当前 buffer 有 LSP 客户端）
  local has_lsp = #vim.lsp.get_clients({ bufnr = bufnr }) > 0
  if has_lsp then
    vim.lsp.buf.hover()
    return
  end

  -- 3. 没有 LSP 也没有注释/字符串时，使用 Neovim 默认 K 行为
  vim.cmd("normal! K")
end

return {
  {
    "noir4y/comment-translate.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("comment-translate").setup({
        -- 这里的目标语言仅用于 comment-translate 内部默认值，实际使用 TARGET_LANGUAGE
        target_language = TARGET_LANGUAGE,
        -- 禁用默认 google 服务；我们使用自定义百度翻译 API
        translate_service = "google",

        hover = {
          enabled = true,
          delay = 500,
          auto = false,
        },

        immersive = {
          enabled = false,
        },

        cache = {
          enabled = true,
          max_entries = 1000,
        },

        targets = {
          comment = true,
          string = true,
        },

        keymaps = {
          hover = false,
          hover_manual = false,
          replace = "<leader>tr",
          toggle = "<leader>tt",
        },
      })

      -- 手动测试命令 :BaiduTranslateTest hello world
      vim.api.nvim_create_user_command("BaiduTranslateTest", function(opts)
        local text = opts.args
        if text == "" then
          vim.notify("用法: :BaiduTranslateTest <要翻译的文本>", vim.log.levels.WARN)
          return
        end
        baidu_translate(text, TARGET_LANGUAGE, function(result)
          if result then
            vim.notify("译文: " .. result, vim.log.levels.INFO)
          end
        end)
      end, { nargs = "*" })

      -- 全局 K 键：翻译注释/字符串 或 LSP hover
      vim.keymap.set("n", "K", smart_hover, { desc = "悬停文档 / 翻译注释" })

      -- LSP 附加后，用同样的逻辑覆盖 buffer-local 的 K 映射
      local group = vim.api.nvim_create_augroup("CommentTranslateK", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          vim.keymap.set("n", "K", smart_hover, {
            buffer = args.buf,
            desc = "悬停文档 / 翻译注释",
            silent = true,
          })
        end,
      })
    end,
  },
}
