-- ==========================================
-- Java 专用配置 (nvim-jdtls)
-- ==========================================

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    config = function()
      local jdtls = require("jdtls")
      local home = os.getenv("HOME")

      -- 自动启动 jdtls 的自动命令
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
          local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

          -- 查找项目根目录
          local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
          local root_dir = require("jdtls.setup").find_root(root_markers)
          if not root_dir then
            root_dir = vim.fn.getcwd()
          end

          -- 查找 java 可执行文件
          local java_path = vim.fn.exepath("java")
          if java_path == "" then
            java_path = "/usr/bin/java"
          end

          -- jdtls 配置
          local config = {
            cmd = {
              "jdtls",
              "--java-executable",
              java_path,
              "-data",
              workspace_dir,
            },

            root_dir = root_dir,

            settings = {
              java = {
                configuration = {
                  updateBuildConfiguration = "interactive",
                },
                maven = {
                  downloadSources = true,
                },
                implementationsCodeLens = {
                  enabled = true,
                },
                referencesCodeLens = {
                  enabled = true,
                },
                references = {
                  includeDecompiledSources = true,
                },
                inlayHints = {
                  parameterNames = {
                    enabled = "all",
                  },
                },
                format = {
                  enabled = true,
                },
                completion = {
                  favoriteStaticMembers = {
                    "org.junit.Assert.*",
                    "org.junit.Assume.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "org.junit.jupiter.api.Assumptions.*",
                    "org.junit.jupiter.api.DynamicContainer.*",
                    "org.junit.jupiter.api.DynamicTest.*",
                    "org.mockito.Mockito.*",
                    "org.mockito.ArgumentMatchers.*",
                    "org.mockito.Answers.*",
                  },
                  importOrder = {
                    "java",
                    "javax",
                    "com",
                    "org",
                  },
                },
                sources = {
                  organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                  },
                },
                codeGeneration = {
                  toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                  },
                  useBlocks = true,
                },
              },
            },

            -- 使用与其他 LSP 相同的能力
            capabilities = require("cmp_nvim_lsp").default_capabilities(),

            on_attach = function(client, bufnr)
              -- 通用 LSP 快捷键
              local map = function(keys, func, desc)
                vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc, noremap = true, silent = true })
              end

              map("gd", vim.lsp.buf.definition, "跳转到定义")
              map("gD", vim.lsp.buf.declaration, "跳转到声明")
              map("gr", vim.lsp.buf.references, "查找引用")
              map("gi", vim.lsp.buf.implementation, "跳转到实现")
              map("K", vim.lsp.buf.hover, "悬停文档")
              map("<C-k>", vim.lsp.buf.signature_help, "签名帮助")
              map("<leader>rn", vim.lsp.buf.rename, "重命名符号")
              map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
              map("<leader>f", function()
                vim.lsp.buf.format({ async = true })
              end, "格式化文档")

              -- Java 特有快捷键
              map("<leader>jo", jdtls.organize_imports, "整理导入")
              map("<leader>jv", jdtls.extract_variable, "提取变量")
              map("<leader>jc", jdtls.extract_constant, "提取常量")
              map("<leader>jm", jdtls.extract_method, "提取方法")
              map("<leader>jt", ":lua require'jdtls'.test_class()<CR>", "测试当前类")
              map("<leader>jn", ":lua require'jdtls'.test_nearest_method()<CR>", "测试最近方法")

              -- 启用文档高亮
              if client:supports_method("textDocument/documentHighlight") then
                local augroup = vim.api.nvim_create_augroup("JdtlsDocumentHighlight" .. bufnr, {})
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
            end,

            -- 拦截补全响应，合并 jdtls 返回的完全重复项（label/kind/detail 相同），
            -- 优先保留有 documentation（注释）的那条
            handlers = {
              ['textDocument/completion'] = function(err, result, ctx, config_handler)
                if err or not result then
                  return vim.lsp.handlers['textDocument/completion'](err, result, ctx, config_handler)
                end

                local items = result.items or result
                if type(items) ~= 'table' then
                  return vim.lsp.handlers['textDocument/completion'](err, result, ctx, config_handler)
                end

                local function has_doc(item)
                  local doc = item.documentation
                  if not doc then return false end
                  if type(doc) == 'string' then return doc ~= '' end
                  if type(doc) == 'table' then
                    return doc.value and doc.value ~= ''
                  end
                  return false
                end

                local seen = {}
                local filtered = {}
                for _, item in ipairs(items) do
                  local key = (item.label or '') .. '|' .. tostring(item.kind or '')
                  if item.detail then
                    key = key .. '|' .. item.detail
                  end
                  if item.labelDetails and item.labelDetails.detail then
                    key = key .. '|' .. item.labelDetails.detail
                  end

                  if not seen[key] then
                    seen[key] = item
                    table.insert(filtered, item)
                  else
                    local existing = seen[key]
                    if not has_doc(existing) and has_doc(item) then
                      for i, v in ipairs(filtered) do
                        if v == existing then
                          filtered[i] = item
                          seen[key] = item
                          break
                        end
                      end
                    end
                  end
                end

                if result.items then
                  result.items = filtered
                else
                  result = filtered
                end
                return vim.lsp.handlers['textDocument/completion'](err, result, ctx, config_handler)
              end,
            },

            init_options = {
              bundles = {},
              extendedClientCapabilities = {
                classFileContentsSupport = true,
                generateToStringPromptSupport = true,
                hashCodeEqualsPromptSupport = true,
                advancedOrganizeImportsSupport = true,
                advancedExtractRefactoringSupport = true,
                inferSelectionSupport = {
                  "extractMethod",
                  "extractVariable",
                  "extractConstant",
                },
                moveRefactoringSupport = true,
                overrideMethodsPromptSupport = true,
                executeClientCommandSupport = true,
              },
            },
          }

          -- 启动或附加 jdtls
          jdtls.start_or_attach(config)
        end,
      })
    end,
  },
}
