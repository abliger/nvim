-- ==========================================
-- 注释/字符串翻译（中文）
-- 基于 noir4y/comment-translate.nvim
-- ==========================================

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

        -- false 表示禁用默认快捷键；K 键在 LSP on_attach 中做智能判断
        keymaps = {
          hover = false,
          hover_manual = false,
          replace = "<leader>tr",
          toggle = "<leader>tt",
        },
      })
    end,
  },
}
