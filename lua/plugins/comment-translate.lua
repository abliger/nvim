-- ==========================================
-- 注释/字符串翻译（中文）
-- 基于 noir4y/comment-translate.nvim
-- ==========================================

local function smart_hover()
  local bufnr = vim.api.nvim_get_current_buf()

  -- 1. 若光标位于注释或字符串上，则翻译并同时显示原文与译文
  local ok_parser, parser = pcall(require, "comment-translate.parser")
  if ok_parser then
    local text = parser.get_text_at_cursor(bufnr)
    if text and text ~= "" then
      local ok_translate, translate = pcall(require, "comment-translate.translate")
      local ok_ui, hover_ui = pcall(require, "comment-translate.ui.hover")
      local ok_config, ct_config = pcall(require, "comment-translate.config")

      if ok_translate and ok_ui and ok_config then
        translate.translate(text, ct_config.config.target_language, nil, function(result)
          if not result or result == "" then
            vim.notify("翻译失败，请检查网络连接", vim.log.levels.ERROR)
            return
          end

          local lines = {
            "# 原文",
            "",
            "```text",
            text,
            "```",
            "",
            "# 译文（" .. ct_config.config.target_language .. "）",
            "",
            result,
          }
          hover_ui.show(table.concat(lines, "\n"))
        end)
        return
      end
    end
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
        -- 目标语言：简体中文
        target_language = "zh-CN",
        -- 使用 Google 翻译（无需 API key）
        translate_service = "google",

        hover = {
          enabled = true,
          delay = 500,
          -- 关闭自动悬停；按 K 时手动触发
          auto = false,
        },

        immersive = {
          enabled = false,
        },

        cache = {
          enabled = true,
          max_entries = 1000,
        },

        -- 同时翻译注释和字符串
        targets = {
          comment = true,
          string = true,
        },

        -- false 表示禁用默认快捷键；K 键在下面统一做智能判断
        keymaps = {
          hover = false,
          hover_manual = false,
          replace = "<leader>tr",
          toggle = "<leader>tt",
        },
      })

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
