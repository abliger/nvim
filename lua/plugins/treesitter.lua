-- ==========================================
-- 语法高亮 (Treesitter)
-- nvim-treesitter v1.0+ 使用原生 vim.lsp 风格 API
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
      -- 同步安装缺失的解析器，避免运行时异步下载导致每次重复
      local ts = require("nvim-treesitter")
      ts.setup({
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })
      local installed = ts.get_installed("parsers")
      for _, lang in ipairs(ensure_installed) do
        if not vim.list_contains(installed, lang) then
          vim.cmd("TSInstallSync " .. lang)
        end
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
}
