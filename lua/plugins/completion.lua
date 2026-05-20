-- ==========================================
-- 代码补全配置
-- ==========================================

return {
  -- 补全引擎
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",           -- LSP 补全源
      "hrsh7th/cmp-buffer",             -- 缓冲区补全源
      "hrsh7th/cmp-path",               -- 路径补全源
      "hrsh7th/cmp-cmdline",            -- 命令行补全源
      "L3MON4D3/LuaSnip",               -- 代码片段引擎
      "saadparwaiz1/cmp_luasnip",       -- LuaSnip 补全源
      "rafamadriz/friendly-snippets",   -- 预定义代码片段
      "onsails/lspkind.nvim",           -- 补全项图标
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      -- 加载 friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- 代码片段配置
      luasnip.config.setup({
        history = true,
        updateevents = "TextChanged,TextChangedI",
      })

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        completion = {
          completeopt = "menu,menuone,noinsert,noselect",
        },
        performance = {
          debounce = 60,
          throttle = 30,
        },

        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- 分组显示：优先显示 LSP，LSP 无结果时再显示后续组，减少重复项
        -- dup = 0 表示同一 source 内 word 完全相同的条目会去重（保留第一个）
        sources = cmp.config.sources(
          { { name = "nvim_lsp", priority = 1000, dup = 0 } },
          { { name = "luasnip", priority = 750 } },
          { { name = "buffer", priority = 500 } },
          { { name = "path", priority = 250 } }
        ),

        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            -- 对于 LSP 补全，将参数签名合并到 abbr 中，以便区分重载函数
            if entry.source.name == "nvim_lsp" then
              local item = entry.completion_item
              local labelDetails = item.labelDetails
              if labelDetails and labelDetails.detail then
                -- labelDetails.detail 通常是参数签名，如 "(a: number): void"
                vim_item.abbr = vim_item.abbr .. " " .. labelDetails.detail
              elseif item.detail and type(item.detail) == "string" then
                vim_item.abbr = vim_item.abbr .. " " .. item.detail
              end
              -- 有文档注释的条目加个小标记，方便在重复项中选到有用的那个
              if item.documentation then
                local doc = item.documentation
                local has_doc = (type(doc) == "string" and doc ~= "")
                  or (type(doc) == "table" and doc.value and doc.value ~= "")
                if has_doc then
                  vim_item.abbr = vim_item.abbr .. " ●"
                end
              end
            end

            local kind = lspkind.cmp_format({
              mode = "symbol_text",
              maxwidth = 60,
              ellipsis_char = "...",
            })(entry, vim_item)

            local menu_map = {
              nvim_lsp = "LSP",
              luasnip = "Snip",
              buffer = "Buf",
              path = "Path",
            }

            -- 在 menu 中显示返回类型或来源描述，帮助区分 Java 中不同来源的同名方法
            local extra = ""
            local item = entry.completion_item
            if item.detail and type(item.detail) == "string" and item.detail ~= "" then
              extra = item.detail
            elseif item.labelDetails and item.labelDetails.description and item.labelDetails.description ~= "" then
              extra = item.labelDetails.description
            end
            if extra ~= "" and #extra < 35 then
              kind.menu = string.format("[%s] %s", menu_map[entry.source.name] or entry.source.name, extra)
            else
              kind.menu = string.format("[%s]", menu_map[entry.source.name] or entry.source.name)
            end

            return kind
          end,
        },

        -- 排序：有文档注释的 LSP 条目优先排在前面
        sorting = {
          comparators = {
            function(entry1, entry2)
              if entry1.source.name == "nvim_lsp" and entry2.source.name == "nvim_lsp" then
                local function has_doc(e)
                  local doc = e.completion_item.documentation
                  if not doc then return false end
                  if type(doc) == "string" then return doc ~= "" end
                  if type(doc) == "table" then return doc.value and doc.value ~= "" end
                  return false
                end
                local d1, d2 = has_doc(entry1), has_doc(entry2)
                if d1 and not d2 then return true end
                if not d1 and d2 then return false end
              end
              return nil
            end,
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },

        experimental = {
          ghost_text = true,
        },
      })

      -- 命令行补全
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
}
