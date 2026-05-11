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
        transparent = false,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = { bold = true },
        },
        sidebars = { "qf", "vista_kind", "terminal", "packer", "neo-tree" },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
