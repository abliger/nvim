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
          -- Rust
          "rust_analyzer",
          -- Go
          "gopls",
          -- 其他
          "lua_ls",
          "yamlls",
          "dockerls",
          "tailwindcss",
        },
        -- macOS 已通过 Command Line Tools 提供 /usr/bin/clangd，
        -- 排除 clangd 避免 Mason 因网络问题反复安装失败。
        automatic_installation = { exclude = { "clangd" } },
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
        map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "上一个诊断")
        map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "下一个诊断")
        map("<leader>ql", vim.diagnostic.setloclist, "定位列表")

        -- 格式化快捷键
        if client:supports_method("textDocument/formatting") then
          map("<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "格式化文档")
        end

        -- Inlay Hints（参数名/类型内联提示）
        -- vtsls/vue_ls 在 Vue 文件中返回的 hint 位置容易越界，触发 Neovim bug
        -- 只在非 Vue 文件或已知稳定的 LSP 上自动启用
        if client:supports_method("textDocument/inlayHint") then
          local ft = vim.bo[bufnr].filetype
          local skip_auto = (ft == "vue" and (client.name == "vtsls" or client.name == "vue_ls"))
          if not skip_auto then
            pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
          end

          -- 手动开关当前 buffer 的 inlay hint
          map("<leader>ih", function()
            local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
            pcall(vim.lsp.inlay_hint.enable, not enabled, { bufnr = bufnr })
          end, "切换 Inlay Hint")
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
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "󰌵",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

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

      -- Vue (Vue Language Server / Volar 2.0+)
      -- 使用 Hybrid Mode：vue_ls 负责 Vue 模板/SFC，vtsls 负责 TS 类型
      vim.lsp.config("vue_ls", {
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "vue" },
        init_options = {
          typescript = {
            -- 优先使用项目本地的 TypeScript，否则用 vtsls 自带的
            tsdk = vim.fs.find("node_modules/typescript/lib", { upward = true })[1]
              or vim.fn.expand("~/.local/share/nvim/mason/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib"),
          },
        },
        settings = {
          vue = {
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
      -- 为 Vue 支持加载 @vue/typescript-plugin
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
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/typescript-plugin",
                  languages = { "vue" },
                  configNamespace = "typescript",
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
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

      -- Swift (sourcekit-lsp)
      local function find_sourcekit_lsp()
        local xcrun_path = vim.trim(vim.fn.system("xcrun --find sourcekit-lsp 2>/dev/null"))
        if vim.v.shell_error == 0 and xcrun_path ~= "" then
          return { xcrun_path }
        end
        local paths = {
          "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
          "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
          "/Library/Developer/CommandLineTools/usr/bin/sourcekit-lsp",
        }
        for _, p in ipairs(paths) do
          if vim.fn.executable(p) == 1 then
            return { p }
          end
        end
        return { "sourcekit-lsp" }
      end

      vim.lsp.config("sourcekit", {
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = find_sourcekit_lsp(),
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_markers = { "Package.swift", ".git", "project.yml", "Project.swift" },
      })
      vim.lsp.enable("sourcekit")

      -- Go
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })
      vim.lsp.enable("gopls")

      -- Rust
      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            procMacro = { enable = true },
            inlayHints = {
              bindingModeHints = { enable = false },
              chainingHints = { enable = true },
              closingBraceHints = { enable = true, minLines = 25 },
              closureReturnTypeHints = { enable = "with_block" },
              lifetimeElisionHints = { enable = "skip_trivial" },
              paramNames = { enable = true },
              typeHints = { enable = true },
            },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")

      -- C / C++
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=bundled",
          "--pch-storage=memory",
          "--cross-file-rename",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", ".git" },
      })
      vim.lsp.enable("clangd")

      -- Java (jdtls) 由 nvim-jdtls 插件处理，这里不配置
    end,
  },

  -- SchemaStore (JSON/YAML schemas)
  { "b0o/schemastore.nvim", lazy = true },
}
