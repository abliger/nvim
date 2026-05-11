-- ==========================================
-- 按键提示 (Which-Key)
-- ==========================================

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      -- 让弹窗可聚焦
      local win = require("which-key.win")
      local orig_defaults = win.defaults
      win.defaults = function(wopts)
        local result = orig_defaults(wopts)
        result.focusable = true
        return result
      end
      require("which-key").setup(opts)
    end,
    opts = {
      preset = "classic",
      delay = 500,
      -- order 优先，分组其次；移除 alphanum 避免字母键插队
      sort = { "order", "group" },
      win = {
        border = "rounded",
        padding = { 1, 2 },
        no_overlap = false,
        title = true,
        title_pos = "center",
      },
      layout = {
        width = { min = 20 },
        spacing = 3,
      },
      keys = {
        scroll_down = "<c-d>",
        scroll_up = "<c-b>",
      },
      plugins = {
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = false,
          g = false,
        },
      },
      spec = {
        -- 第一行：按键帮助
        { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "按键帮助", order = 1 },
        -- 分组
        { "<leader>d", group = "调试/诊断", icon = { icon = "", color = "red" }, order = 10 },
        { "<leader>g", group = "Git", icon = { icon = "", color = "orange" }, order = 10 },
        { "<leader>h", group = "代码块", icon = { icon = "", color = "orange" }, order = 10 },
        { "<leader>j", group = "Java", icon = { icon = "", color = "yellow" }, order = 10 },
        { "<leader>x", group = "问题列表", icon = { icon = "", color = "red" }, order = 10 },
      },
    },
  },
}
