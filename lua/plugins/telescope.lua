-- ==========================================
-- 模糊查找 (Telescope)
-- ==========================================

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      "ahmedkhalf/project.nvim",
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "查找文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全局搜索" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "查找缓冲区" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "帮助标签" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "最近文件" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "搜索光标下文本" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "命令列表" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "快捷键列表" },
      { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "项目列表" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          mappings = {
            i = {
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-c>"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            "target",
            "dist",
            "build",
            ".git",
            "%.class",
            "%.jar",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
      telescope.load_extension("projects")
    end,
  },
}
