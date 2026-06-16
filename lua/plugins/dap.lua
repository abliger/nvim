-- ==========================================
-- 调试配置 (DAP)
-- ==========================================

return {
  -- 调试适配器协议
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "调试: 继续" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "调试: 切换断点" },
      { "<F10>", function() require("dap").step_over() end, desc = "调试: 单步跳过" },
      { "<F11>", function() require("dap").step_into() end, desc = "调试: 单步进入" },
      { "<F12>", function() require("dap").step_out() end, desc = "调试: 单步跳出" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "调试: 切换断点" },
      { "<leader>dB", function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, desc = "调试: 条件断点" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "调试: 打开 REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "调试: 重新运行上次" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "调试: 切换 UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- DAP UI 配置
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          element = "repl",
          icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "↻",
            terminate = "",
          },
        },
      })

      -- 虚拟文本
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        filter_references_pattern = ".module.",
        virt_text_pos = "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })

      -- DAP 事件监听
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Rust / C / C++ 调试适配器 (codelldb)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- C / C++ 调试 (使用 codelldb)
      dap.configurations.c = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      dap.configurations.cpp = dap.configurations.c

      -- Swift 调试 (使用 codelldb)
      dap.configurations.swift = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/.build/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- Java 调试适配器 (由 nvim-jdtls 自动配置)
      -- 这里可以添加其他语言的适配器配置
    end,
  },
}
