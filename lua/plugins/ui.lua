-- ==========================================
-- UI 相关插件
-- ==========================================

return {
  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- 缓冲区标签
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          separator_style = "slant",
          always_show_bufferline = true,
          diagnostics = "nvim_lsp",
          offsets = {
            {
              filetype = "neo-tree",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left",
            },
          },
        },
      })
    end,
  },

  -- 文件浏览器
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>e", function() require("neo-tree.command").execute({ toggle = true }) end, desc = "切换文件浏览器" },
      { "<leader>o", function() require("neo-tree.command").execute({ reveal = true, reveal_force_cwd = true }) end, desc = "定位当前文件" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    init = function()
      -- 启动时若首参为目录，提前加载 neo-tree 以便其接管目录缓冲区
      if vim.fn.argc(-1) == 1 then
        local stat = vim.uv.fs_stat(tostring(vim.fn.argv(0)))
        if stat and stat.type == "directory" then
          require("neo-tree")
        end
      end
    end,
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        filesystem = {
          -- 接管目录缓冲区，使 `nvim .` 直接显示文件树
          hijack_netrw_behavior = "open_default",
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_by_name = {
              "node_modules",
              ".git",
              "target",
              "dist",
            },
          },
          -- 打开文件时自动展开目录树并定位到当前文件
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = false,
          -- 将只有一个子目录的空文件夹合并显示（Java 包结构 com/xx/xxx）
          group_empty_dirs = true,
          -- 深度扫描，一开始就递归加载所有目录，配合 group_empty_dirs 显示完整折叠效果
          scan_mode = "deep",
        },
        -- 打开文件时不要替换这些特殊类型的窗口
        open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "Outline" },
        window = {
          width = 35,
          mappings = {
            ["<space>"] = "none",
          },
        },
        default_component_configs = {
          indent = {
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
        },
      })
    end,
  },

  -- 通知美化
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      vim.notify = require("notify")
      require("notify").setup({
        timeout = 3000,
        max_height = function()
          return math.floor(vim.o.lines * 0.75)
        end,
        max_width = function()
          return math.floor(vim.o.columns * 0.75)
        end,
      })
    end,
  },

  -- 缩进指示线
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    config = function()
      require("ibl").setup({
        scope = { enabled = true },
        exclude = {
          filetypes = {
            "help",
            "neo-tree",
            "Trouble",
            "lazy",
            "mason",
          },
        },
      })
    end,
  },

  -- 图标
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
