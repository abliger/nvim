-- ==========================================
-- Git 集成
-- ==========================================

-- 在 Neogit commit buffer 中自动注册 AI 生成快捷键
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NeogitCommitMessage",
  callback = function(args)
    vim.keymap.set("n", "<C-g>", function()
      require("config.git_ai").generate_and_insert()
    end, { buffer = args.buf, desc = "AI 生成提交信息" })
  end,
})

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
      { "<leader>ga", ":Git add .<CR>", desc = "Git 添加所有" },
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

          ---@param msg string
          local function notify(msg)
            vim.notify(msg, vim.log.levels.INFO)
          end

          ---关闭所有 fugitive 相关的 diff 窗口，保留普通文件窗口
          local function close_fugitive_wins()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local name = vim.api.nvim_buf_get_name(buf)
              if name:match("^fugitive://") then
                vim.api.nvim_win_close(win, false)
              end
            end
          end

          if vim.g.diff_follow then
            -- 关闭跟随模式
            vim.g.diff_follow = false
            vim.g.last_diff_buf = nil
            vim.api.nvim_clear_autocmds({ group = diff_group })
            close_fugitive_wins()
            vim.cmd("diffoff!")
            notify("Diff 跟随模式已关闭")
            return
          end

          -- 启动跟随模式
          vim.g.diff_follow = true
          vim.g.last_diff_buf = vim.fn.bufname("%")
          vim.cmd("Gvdiffsplit!")
          notify("Diff 跟随模式已开启，切换文件自动更新 diff（再按 <leader>gd 退出）")

          vim.api.nvim_create_autocmd("BufEnter", {
            group = diff_group,
            pattern = "*",
            callback = function()
              if not vim.g.diff_follow then
                return
              end

              local bufname = vim.fn.bufname("%")
              -- 跳过空 buffer、fugitive 内部缓冲区和特殊缓冲区
              if bufname == "" or bufname:match("^fugitive://") or vim.bo.buftype ~= "" then
                return
              end

              -- 避免在 diff 视图内切换窗口时重复刷新
              if bufname == vim.g.last_diff_buf then
                return
              end
              vim.g.last_diff_buf = bufname

              -- 延迟到文件加载完成后再执行，避免干扰 neo-tree 等插件的打开流程
              vim.schedule(function()
                if not vim.g.diff_follow or vim.bo.buftype ~= "" then
                  return
                end

                -- 精准关闭 fugitive diff 窗口，保留工作文件和其他辅助窗口
                close_fugitive_wins()

                -- 为新文件启动 diff（未跟踪文件会静默失败）
                pcall(vim.cmd, "Gvdiffsplit!")
              end)
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

  -- Neogit: 类似 VSCode 的 Git 面板
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    config = function()
      require("neogit").setup({
        kind = "tab",
        signs = {
          section = { ">", "v" },
          item = { ">", "v" },
          hunk = { "", "" },
        },
        integrations = {
          diffview = true,
          telescope = true,
        },
      })
    end,
    keys = {
      {
        "<leader>gg",
        function()
          require("neogit").open({ kind = "vsplit" })
          vim.cmd("wincmd H")
        end,
        desc = "打开 Neogit (左侧)",
      },
      {
        "<leader>gC",
        function()
          require("config.git_ai").generate_and_copy()
        end,
        desc = "AI 生成提交信息到剪贴板",
      },
    },
  },
}
