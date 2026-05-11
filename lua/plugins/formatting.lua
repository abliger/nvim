-- ==========================================
-- 代码格式化
-- ==========================================

return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          -- Java (由 jdtls 处理，但也可以配置备用)
          java = { "google-java-format" },
          -- Vue / 前端 -> 使用 oxfmt
          vue = { "oxfmt" },
          javascript = { "oxfmt" },
          javascriptreact = { "oxfmt" },
          typescript = { "oxfmt" },
          typescriptreact = { "oxfmt" },
          css = { "oxfmt" },
          scss = { "oxfmt" },
          less = { "oxfmt" },
          html = { "oxfmt" },
          json = { "oxfmt" },
          jsonc = { "oxfmt" },
          yaml = { "oxfmt" },
          markdown = { "oxfmt" },
          -- Lua
          lua = { "stylua" },
          -- Shell
          sh = { "shfmt" },
        },

        formatters = {
          oxfmt = {
            command = "oxfmt",
            args = { "--stdin" },
            stdin = true,
          },
          stylua = {
            prepend_args = {
              "--indent-width",
              "2",
              "--indent-type",
              "Spaces",
              "--column-width",
              "120",
            },
          },
        },

        format_on_save = {
          timeout_ms = 2000,
          lsp_fallback = true,
        },

        notify_on_error = true,
      })

      -- 手动格式化快捷键
      vim.keymap.set({ "n", "v" }, "<leader>F", function()
        require("conform").format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 2000,
        })
      end, { desc = "手动格式化文件或选中区域" })
    end,
  },
}
