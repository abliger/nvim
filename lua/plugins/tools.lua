-- ==========================================
-- 实用工具插件
-- ==========================================

return {
  -- 终端集成
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- Lazygit 终端
      local Terminal = require("toggleterm.terminal").Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
        on_close = function()
          vim.cmd("startinsert!")
        end,
      })

      function _lazygit_toggle()
        lazygit:toggle()
      end

      -- 运行当前文件的终端（按文件类型自动选择命令）
      local run_term = Terminal:new({
        direction = "float",
        close_on_exit = false,
        float_opts = { border = "curved" },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        end,
      })

      function _run_current_file()
        local ft = vim.bo.filetype
        local filepath = vim.fn.expand("%:p")
        local cmd = nil

        local runners = {
          python = "python3",
          javascript = "node",
          typescript = "npx ts-node",
          sh = "bash",
          lua = "lua",
          go = "go run",
          rust = "cargo run",
          java = "java",
        }

        if runners[ft] then
          cmd = runners[ft] .. " " .. vim.fn.shellescape(filepath)
        end

        if cmd then
          run_term.cmd = cmd
          run_term:open()
        else
          vim.notify("没有为文件类型 '" .. ft .. "' 配置运行命令", vim.log.levels.WARN)
        end
      end

      -- 运行自定义命令（会弹出输入框）
      function _run_custom_command()
        vim.ui.input({ prompt = "Run: " }, function(input)
          if input and input ~= "" then
            local custom = Terminal:new({
              cmd = input,
              direction = "float",
              close_on_exit = false,
              float_opts = { border = "curved" },
              on_open = function(term)
                vim.cmd("startinsert!")
                vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
              end,
            })
            custom:open()
          end
        end)
      end
    end,
    keys = {
      { "<leader>t", ":ToggleTerm<CR>", desc = "切换终端" },
      { "<leader>tg", ":lua _lazygit_toggle()<CR>", desc = "切换 lazygit" },
      { "<leader>tr", ":lua _run_current_file()<CR>", desc = "运行当前文件" },
      { "<leader>tc", ":lua _run_custom_command()<CR>", desc = "运行自定义命令" },
    },
  },

  -- 快速注释
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  -- 成对符号操作
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  -- 高亮当前单词
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        providers = {
          "lsp",
          "treesitter",
          "regex",
        },
        delay = 100,
        filetype_overrides = {},
        filetypes_denylist = {
          "dirvish",
          "fugitive",
          "neo-tree",
          "alpha",
          "NvimTree",
          "lazy",
          "neogitstatus",
          "Trouble",
          "lir",
          "Outline",
          "spectre_panel",
          "toggleterm",
          "DressingSelect",
          "TelescopePrompt",
        },
        filetypes_allowlist = {},
        modes_denylist = {},
        modes_allowlist = {},
        providers_regex_syntax_denylist = {},
        providers_regex_syntax_allowlist = {},
        under_cursor = true,
      })
    end,
  },

  -- 自动括号配对
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          java = false,
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", '"', "'" },
          pattern = string.gsub([[ [%'%)%>%]%)%}%,] ]], "%s+", ""),
          offset = 0,
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "PmenuSel",
          highlight_grey = "LineNr",
        },
      })

      -- 与 nvim-cmp 集成
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({ map_char = { tex = "" } }))
    end,
  },

  -- 大纲/符号列表
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>so", "<cmd>Outline<CR>", desc = "切换符号大纲" },
    },
    config = function()
      require("outline").setup({
        outline_window = {
          position = "right",
          width = 25,
          relative_width = true,
        },
        keymaps = {
          close = { "<Esc>", "q" },
          goto_location = "<Cr>",
          goto_and_close = "o",
          hover_symbol = "K",
          rename_symbol = "r",
          code_actions = "a",
          fold = "h",
          unfold = "l",
          fold_all = "W",
          unfold_all = "E",
          fold_reset = "R",
        },
      })
    end,
  },

  -- 问题列表
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleRefresh" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "诊断列表 (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "缓冲区诊断 (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "符号列表 (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP 定义/引用 (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "位置列表 (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "快速修复列表 (Trouble)" },
    },
    config = function()
      require("trouble").setup({
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_fold = false,
        use_diagnostic_signs = true,
      })
    end,
  },

  -- 项目管理
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "pom.xml", "package.json", "=src" },
        silent_chdir = true,
        scope_chdir = "global",
      })
    end,
  },

  -- 快速跳转
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    event = "VeryLazy",
    config = function()
      local leap = require("leap")
      -- 创建重复跳转的快捷键 (Sneak-style 映射)
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
      vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)")
    end,
  },

  -- 代码检查 (Linter) -> 使用 oxlint 替代 eslint
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
        vue = { "oxlint" },
      }

      -- oxlint 使用项目中的 .oxlintrc.json 配置
      lint.linters.oxlint = {
        cmd = "oxlint",
        stdin = false,
        args = {
          "--format", "json",
          "$FILENAME",
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = function(output, bufnr, linter_cwd)
          if output == "" then
            return {}
          end

          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded or not decoded.messages then
            return {}
          end

          local diagnostics = {}
          for _, msg in ipairs(decoded.messages) do
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = (msg.line or 1) - 1,
              col = (msg.column or 1) - 1,
              end_lnum = (msg.endLine or msg.line or 1) - 1,
              end_col = (msg.endColumn or msg.column or 1) - 1,
              severity = msg.severity == 2 and vim.diagnostic.severity.ERROR
                         or msg.severity == 1 and vim.diagnostic.severity.WARNING
                         or vim.diagnostic.severity.INFO,
              message = msg.message,
              source = "oxlint",
              code = msg.ruleId,
            })
          end
          return diagnostics
        end,
      }

      -- 保存时自动运行 lint
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("NvimLint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- 会话管理
  {
    "rmagatti/auto-session",
    event = "VimEnter",
    config = function()
      require("auto-session").setup({
        log_level = "error",
        suppressed_dirs = { "~/", "~/Downloads", "/" },
        git_use_branch_name = true,
        -- 不自动恢复上次会话，改为启动时手动选择
        auto_restore = false,
        -- 退出时仍然自动保存会话
        auto_save = true,
        -- session 选择器配置
        session_lens = {
          load_on_setup = true,
          picker_opts = { border = true },
          previewer = false,
        },
      })
    end,
    keys = {
      { "<leader>S", "<cmd>AutoSession search<CR>", desc = "搜索 Session" },
    },
  },
}
