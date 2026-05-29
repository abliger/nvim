-- ==========================================
-- 主题配置
-- ==========================================

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = { bold = true },
        },
        sidebars = { "qf", "vista_kind", "terminal", "packer" },
        on_highlights = function(hl, c)
          hl.NeoTreeNormal = { link = "Normal" }
          hl.NeoTreeNormalNC = { link = "NormalNC" }
          hl.NeoTreeEndOfBuffer = { link = "EndOfBuffer" }
          hl.NeoTreeWinSeparator = { link = "WinSeparator" }
        end,
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
