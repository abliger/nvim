-- ==========================================
-- 语法高亮 (Treesitter)
-- nvim-treesitter v1.0+ 使用原生 API
-- ==========================================

local ensure_installed = {
  "java",
  "vue",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "scss",
  "json",
  "yaml",
  "toml",
  "xml",
  "sql",
  "lua",
  "vim",
  "vimdoc",
  "bash",
  "markdown",
  "markdown_inline",
  "regex",
  "dockerfile",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      -- v1.0+ 使用 Lua API 同步安装，避免运行时重复下载
      local ts = require("nvim-treesitter")
      ts.setup({
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })
      local installed = ts.get_installed("parsers")
      local to_install = {}
      for _, lang in ipairs(ensure_installed) do
        if not vim.list_contains(installed, lang) then
          table.insert(to_install, lang)
        end
      end
      if #to_install > 0 then
        local task = ts.install(to_install, { summary = true })
        task:wait()
      end
    end,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ts = require("nvim-treesitter")

      -- 设置安装目录
      ts.setup({
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })

      -- nvim-ts-context-commentstring: 让 Vue 各区块注释正确
      -- (template→<!-- -->, script→//, style→/* */)
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })

      -- Neovim 0.11+ 原生 Treesitter 高亮与缩进
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local ok = pcall(vim.treesitter.start, buf)
          if ok then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- ==========================================
      -- nvim-treesitter-textobjects 配置
      -- ==========================================
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {},
        },
        move = {
          set_jumps = true,
        },
      })

      local select_obj = require("nvim-treesitter-textobjects.select")
      local move_obj = require("nvim-treesitter-textobjects.move")

      -- 选择 textobjects
      local function map_select(modes, key, query)
        vim.keymap.set(modes, key, function()
          select_obj.select_textobject(query, "textobjects")
        end, { silent = true, desc = "选择 " .. query })
      end

      map_select({ "x", "o" }, "af", "@function.outer")
      map_select({ "x", "o" }, "if", "@function.inner")
      map_select({ "x", "o" }, "ac", "@class.outer")
      map_select({ "x", "o" }, "ic", "@class.inner")
      map_select({ "x", "o" }, "ai", "@conditional.outer")
      map_select({ "x", "o" }, "ii", "@conditional.inner")
      map_select({ "x", "o" }, "al", "@loop.outer")
      map_select({ "x", "o" }, "il", "@loop.inner")
      map_select({ "x", "o" }, "ap", "@parameter.outer")
      map_select({ "x", "o" }, "ip", "@parameter.inner")

      -- 移动 textobjects
      local function map_move(key, method, queries)
        vim.keymap.set({ "n", "x", "o" }, key, function()
          method(queries, "textobjects")
        end, { silent = true, desc = "跳转到 " .. queries[1] })
      end

      map_move("]f", move_obj.goto_next_start, { "@function.outer" })
      map_move("]F", move_obj.goto_next_end, { "@function.outer" })
      map_move("[f", move_obj.goto_previous_start, { "@function.outer" })
      map_move("[F", move_obj.goto_previous_end, { "@function.outer" })
      map_move("]c", move_obj.goto_next_start, { "@class.outer" })
      map_move("]C", move_obj.goto_next_end, { "@class.outer" })
      map_move("[c", move_obj.goto_previous_start, { "@class.outer" })
      map_move("[C", move_obj.goto_previous_end, { "@class.outer" })
    end,
  },

  -- ==========================================
  -- 自动标签（Vue/HTML/XML 标签自动闭合/重命名）
  -- ==========================================
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = true,
        },
        per_filetype = {
          ["vue"] = {
            enable_close = true,
            enable_rename = true,
            enable_close_on_slash = true,
          },
        },
      })
    end,
  },

  -- ==========================================
  -- 彩虹括号（Vue 模板嵌套标签层级可视化）
  -- ==========================================
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
          vim = rainbow.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        priority = {
          [""] = 110,
          lua = 210,
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },

  -- ==========================================
  -- 参数高亮（让函数参数和变量颜色区分）
  -- ==========================================
  {
    "m-demare/hlargs.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("hlargs").setup({
        color = "#ef9062",
        highlight = {},
        excluded_filetypes = {},
        paint_arg_declarations = true,
        paint_arg_usages = true,
        paint_catch_blocks = false,
        extras = {
          named_parameters = false,
        },
        hl_priority = 120,
        excluded_argnames = {
          declarations = {},
          usages = {
            python = { "self", "cls" },
            lua = { "self" },
          },
        },
        performance = {
          animation_redraw = false,
        },
      })
    end,
  },
}
