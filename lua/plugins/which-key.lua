-- ==========================================
-- 按键提示 (Which-Key)
-- ==========================================

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("which-key").setup(opts)
      -- 让弹窗可聚焦（默认 focusable = false 被硬编码覆盖）
      local win = require("which-key.win")
      local orig_defaults = win.defaults
      win.defaults = function(wopts)
        local result = orig_defaults(wopts)
        result.focusable = true
        return result
      end
      -- 兜底：setup 的 load 是异步 schedule 的，如果用户立刻按 <leader>?
      -- config.lua 的 __index 会返回 opts.triggers（defaults 数组，没有 modes 字段），
      -- 必须用 rawget 绕过 __index，直接给 M.triggers 赋一个含 modes 的空表
      local cfg = require("which-key.config")
      if not rawget(cfg, "triggers") then
        rawset(cfg, "triggers", { mappings = {}, modes = {} })
      end
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
          operators = true,
          motions = true,
          text_objects = true,
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
      },
      spec = {
        -- 第一行：按键帮助
        { "<leader>?", function() require("which-key").show({ global = true }) end, desc = "按键帮助", order = 1 },
        -- 分组
        { "<leader>d", group = "调试/诊断", icon = { icon = "", color = "red" }, order = 10 },
        { "<leader>e", group = "文件浏览器", icon = { icon = "", color = "cyan" }, order = 10 },
        { "<leader>f", group = "查找 (Telescope)", icon = { icon = "", color = "blue" }, order = 10 },
        { "<leader>g", group = "Git", icon = { icon = "", color = "orange" }, order = 10 },
        { "<leader>h", group = "Git 代码块", icon = { icon = "", color = "orange" }, order = 10 },
        { "<leader>j", group = "Java", icon = { icon = "", color = "yellow" }, order = 10 },
        { "<leader>c", group = "代码/LSP", icon = { icon = "", color = "blue" }, order = 10 },
        { "<leader>bd", desc = "关闭缓冲区", order = 10 },
        { "<leader>s", group = "符号/大纲", icon = { icon = "", color = "purple" }, order = 10 },
        -- 隐藏基础操作键，避免干扰分组显示
        { "<leader>qq", desc = "退出", order = 10 },
        { "<leader>t", group = "终端", icon = { icon = "", color = "green" }, order = 10 },
        { "<leader>x", group = "问题列表", icon = { icon = "", color = "red" }, order = 10 },
      },
    },
  },
}
