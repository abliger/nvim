-- ==========================================
-- 代码格式化
-- ==========================================

return {
  -- 自动安装 Mason 工具（formatter / linter / DAP）
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Formatter
          "stylua",
          "shfmt",
          "oxfmt",
          "clang-format",
          -- Linter
          "oxlint",
        },
        auto_update = false,
        run_on_start = true,
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          -- Java 由 jdtls 处理，不额外配置 formatter
          -- Vue / 前端 -> 使用 oxfmt（JS/TS/Vue/JSON）
          vue = { "oxfmt" },
          javascript = { "oxfmt" },
          javascriptreact = { "oxfmt" },
          typescript = { "oxfmt" },
          typescriptreact = { "oxfmt" },
          json = { "oxfmt" },
          jsonc = { "oxfmt" },
          -- Lua
          lua = { "stylua" },
          -- Shell
          sh = { "shfmt" },
          -- Go
          go = { "gofumpt" },
          -- C / C++
          c = { "clang-format" },
          cpp = { "clang-format" },
        },
        formatters = {
          gofumpt = {
            command = "gofumpt",
            args = {},
            stdin = true,
          },

          oxfmt = {
            command = "oxfmt",
            args = { "--stdin-filepath", "$FILENAME" },
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
