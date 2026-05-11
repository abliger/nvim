-- ==========================================
-- LSP (语言服务器协议) 配置
-- Neovim 0.11+ 使用 vim.lsp.config / vim.lsp.enable
-- ==========================================

return {
  -- Mason: LSP/DAP/linter/formatter 管理器
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "",
            package_pending = "",
            package_uninstalled = "",
          },
        },
      })
    end,
  },

  -- Mason 自动安装管理 (nvim-lspconfig v2 兼容方式)
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Java
          "jdtls",
          -- Vue / 前端
          "vue_ls",
          "vtsls",
          -- CSS/HTML/JSON
          "cssls",
          "html",
          "jsonls",
          -- 其他
          "lua_ls",
          "yamlls",
          "dockerls",
          "tailwindcss",
        },
        automatic_installation = true,
      })
    end,
  },

  -- nvim-lspconfig: 提供 LSP 默认配置（不再调用 lspconfig.xxx.setup）
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "antosha417/nvim-lsp-file-operations", config = true },
    },
    config = function()
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      -- 通用的 LSP 客户端能力
      local capabilities = cmp_nvim_lsp.default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      -- LSP 附加函数
      local on_attach = function(client, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc, noremap = true, silent = true })
        end

        -- 快捷键
        map("gd", vim.lsp.buf.definition, "跳转到定义")
        map("gD", vim.lsp.buf.declaration, "跳转到声明")
        map("gr", vim.lsp.buf.references, "查找引用")
        map("gi", vim.lsp.buf.implementation, "跳转到实现")
        map("K", vim.lsp.buf.hover, "悬停文档")
        map("<C-k>", vim.lsp.buf.signature_help, "签名帮助")
        map("<leader>rn", vim.lsp.buf.rename, "重命名符号")
        map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
        map("<leader>D", vim.lsp.buf.type_definition, "类型定义")
        map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "文档符号")
        map("<leader>ws", require("telescope.builtin").lsp_workspace_symbols, "工作区符号")
        map("<leader>dl", vim.diagnostic.open_float, "行诊断")
        map("[d", vim.diagnostic.goto_prev, "上一个诊断")
        map("]d", vim.diagnostic.goto_next, "下一个诊断")
        map("<leader>q", vim.diagnostic.setloclist, "定位列表")

        -- 格式化快捷键
        if client:supports_method("textDocument/formatting") then
          map("<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "格式化文档")
        end

        -- Inlay Hints（参数名/类型内联提示）
        if client:supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end

        -- 自动签名帮助：输入 ( 或 , 时自动显示函数签名
        if client:supports_method("textDocument/signatureHelp") then
          local sig_group = vim.api.nvim_create_augroup("LspSignatureHelp" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd("TextChangedI", {
            group = sig_group,
            buffer = bufnr,
            callback = function()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              local line = vim.api.nvim_get_current_line()
              local char = line:sub(col, col)
              if char == "(" or char == "," then
                vim.lsp.buf.signature_help()
              end
            end,
          })
        end

        -- 文档高亮
        if client:supports_method("textDocument/documentHighlight") then
          local augroup = vim.api.nvim_create_augroup("LspDocumentHighlight" .. bufnr, {})
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = augroup,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = augroup,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end

      -- 诊断配置
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          source = "if_many",
        },
        float = {
          border = "rounded",
          source = "always",
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- 诊断图标
      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "󰌵" },
        { name = "DiagnosticSignInfo", text = "" },
      }
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end

      -- ==========================================
      -- Neovim 0.11+ 原生 LSP 配置方式
      -- vim.lsp.config(name, opts) + vim.lsp.enable(name)
      -- ==========================================

      -- Lua
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable("lua_ls")

      -- Vue (Volar)
      vim.lsp.config("vue_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "vue" },
        init_options = {
          vue = {
            hybridMode = false,
          },
          typescript = {
            -- 让 Volar 使用工作区中的 TypeScript
            tsdk = vim.fs.find("node_modules/typescript/lib", { upward = true, path = vim.fn.getcwd() })[1]
              or vim.fn.expand("~/.local/share/nvim/mason/packages/typescript-language-server/node_modules/typescript/lib"),
          },
        },
        settings = {
          vue = {
            -- 自动导入组件
            complete = {
              casing = {
                tags = "kebab",
                props = "camel",
              },
            },
          },
        },
      })
      vim.lsp.enable("vue_ls")

      -- TypeScript (vtsls)
      vim.lsp.config("vtsls", {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
        },
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {},
            },
          },
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
            },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
            },
          },
        },
      })
      vim.lsp.enable("vtsls")

      -- CSS
      vim.lsp.config("cssls", {
        capabilities = capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable("cssls")

      -- HTML
      vim.lsp.config("html", {
        capabilities = capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable("html")

      -- JSON
      vim.lsp.config("jsonls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })
      vim.lsp.enable("jsonls")

      -- YAML
      vim.lsp.config("yamlls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          yaml = {
            schemas = require("schemastore").yaml.schemas(),
            validate = true,
          },
        },
      })
      vim.lsp.enable("yamlls")

      -- Tailwind CSS
      vim.lsp.config("tailwindcss", {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
      vim.lsp.enable("tailwindcss")

      -- Docker
      vim.lsp.config("dockerls", {
        capabilities = capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable("dockerls")

      -- Java (jdtls) 由 nvim-jdtls 插件处理，这里不配置
    end,
  },

  -- SchemaStore (JSON/YAML schemas)
  { "b0o/schemastore.nvim", lazy = true },
}
