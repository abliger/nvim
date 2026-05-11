-- ==========================================
-- Git 集成
-- ==========================================

return {
  -- Git 标记
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          follow_files = true,
        },
        auto_attach = true,
        attach_to_untracked = true,
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
          use_focus = true,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
          border = "single",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- 导航
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "下一个代码块" })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "上一个代码块" })

          -- 动作
          map("n", "<leader>hs", gs.stage_hunk, { desc = "暂存代码块" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "重置代码块" })
          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "暂存选中代码块" })
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "重置选中代码块" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "暂存整个缓冲区" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "撤销暂存代码块" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "重置整个缓冲区" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "预览代码块" })
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, { desc = "查看行作者" })
          map("n", "<leader>hd", gs.diffthis, { desc = "当前文件差异" })
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end, { desc = "当前文件差异 (~)" })
          map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "切换行作者显示" })
          map("n", "<leader>td", gs.toggle_deleted, { desc = "切换删除标记" })
        end,
      })
    end,
  },

  -- Git 命令集成
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = {
      { "<leader>gs", ":Git<CR>", desc = "Git 状态" },
      { "<leader>gc", ":Git commit<CR>", desc = "Git 提交" },
      { "<leader>gp", ":Git push<CR>", desc = "Git 推送" },
      { "<leader>gl", ":Git pull<CR>", desc = "Git 拉取" },
      { "<leader>gb", ":Git blame<CR>", desc = "Git 追责" },
      { "<leader>gL", ":Git log<CR>", desc = "Git 日志" },
      {
        "<leader>gd",
        function()
          local diff_group = vim.api.nvim_create_augroup("DiffFollow", { clear = true })

          if vim.g.diff_follow then
            -- 关闭跟随模式
            vim.g.diff_follow = false
            vim.api.nvim_clear_autocmds({ group = diff_group })
            vim.cmd("diffoff!")
            if vim.fn.winnr("$") > 1 then
              vim.cmd("wincmd o")
            end
            vim.notify("Diff 跟随模式已关闭", vim.log.levels.INFO)
            return
          end

          -- 启动跟随模式
          vim.g.diff_follow = true
          vim.cmd("Gvdiffsplit!")
          vim.notify("Diff 跟随模式已开启，切换文件自动更新 diff（再按 <leader>gd 退出）", vim.log.levels.INFO)

          vim.api.nvim_create_autocmd("BufEnter", {
            group = diff_group,
            pattern = "*",
            callback = function()
              if not vim.g.diff_follow then
                return
              end

              local bufname = vim.fn.bufname("%")
              -- 跳过 fugitive 内部缓冲区和特殊缓冲区
              if bufname:match("^fugitive://") or vim.bo.buftype ~= "" then
                return
              end

              -- 关闭当前 diff，只保留当前窗口
              vim.cmd("diffoff!")
              if vim.fn.winnr("$") > 1 then
                vim.cmd("wincmd o")
              end

              -- 为新文件启动 diff（未跟踪文件会静默失败）
              pcall(vim.cmd, "Gvdiffsplit!")
            end,
          })
        end,
        desc = "Git 差异跟随 (左右)",
      },
    },
  },

  -- Diff 查看
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      { "<leader>gD", ":DiffviewOpen<CR>", desc = "打开差异视图" },
    },
  },
}
