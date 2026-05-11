# Neovim 配置 - Java + Vue 全栈开发

为 `/Users/lvming/Downloads/project/` 项目定制的 Neovim 配置，支持 Java 后端和 Vue 前端开发。

## 项目结构

```
/Users/lvming/Downloads/project/
├── smart_switch/              # Java 后端 (Maven 多模块)
│   ├── smart-switch-service/
│   ├── smart-switch-web/
│   ├── smart-switch-common/
│   ├── smart-switch-auth/
│   └── pom.xml
├── SmartSwitch/               # Vue3 + Taro 小程序前端
└── SmartSwitchManagement/     # Vue3 + Vite + Element Plus 管理后台
```

## 依赖要求

### 必需

- **Neovim >= 0.9**
- **Git**
- **Node.js >= 16** (用于前端 LSP)
- **Java >= 17** (用于 Java 开发)
- **Maven** 或 **Gradle**

### 可选但推荐

- **ripgrep (rg)** - Telescope 更快搜索
- **fd** - Telescope 更快文件查找
- **lazygit** - 终端 Git 客户端
- **java-debug-adapter** - Java 调试

## 安装步骤

### 1. 安装 Neovim

```bash
brew install neovim
```

### 2. 安装依赖工具

```bash
# 基础工具
brew install git ripgrep fd lazygit node

# Java 开发
brew install openjdk@17 maven

# 格式化工具 (通过 Mason 自动安装，也可手动安装)
npm install -g prettier
brew install google-java-format stylua shfmt
```

### 3. 首次启动

```bash
nvim
```

首次启动时会自动下载安装 `lazy.nvim` 插件管理器和所有插件。安装完成后重启 Neovim。

### 4. 安装 LSP/DAP/工具

在 Neovim 中运行：

```vim
:Mason
```

确保以下工具已安装：

- `jdtls` - Java 语言服务器
- `vue_ls` - Vue 语言服务器
- `vtsls` - TypeScript 语言服务器
- `cssls` - CSS 语言服务器
- `html` - HTML 语言服务器
- `jsonls` - JSON 语言服务器
- `yamlls` - YAML 语言服务器
- `tailwindcss` - Tailwind CSS 语言服务器
- `lua_ls` - Lua 语言服务器
- `oxfmt` - 前端代码格式化 (oxc)
- `google-java-format` - Java 代码格式化
- `oxlint` - JavaScript/TypeScript/Vue 静态检查 (oxc)

## 快捷键

### 基础操作

| 快捷键 | 功能 |
|--------|------|
| `Space` | Leader 键 |
| `jk` / `kj` | 退出插入模式 |
| `<leader>w` | 保存文件 |
| `<leader>q` | 退出 |
| `<leader>ev` | 编辑 Neovim 配置 |

### 文件导航

| 快捷键 | 功能 |
|--------|------|
| `<leader>e` | 切换文件浏览器 |
| `<leader>o` | 在文件浏览器中定位当前文件 |
| `<leader>ff` | 查找文件 |
| `<leader>fg` | 全局搜索文本 |
| `<leader>fb` | 查找缓冲区 |
| `<leader>fr` | 最近文件 |

### 窗口操作

| 快捷键 | 功能 |
|--------|------|
| `<C-h/j/k/l>` | 切换窗口 |
| `<C-方向键>` | 调整窗口大小 |
| `<S-h/l>` | 切换缓冲区 |
| `<leader>c` | 关闭缓冲区 |

### LSP (代码导航)

| 快捷键 | 功能 |
|--------|------|
| `gd` | 跳转到定义 |
| `gD` | 跳转到声明 |
| `gr` | 查找引用 |
| `gi` | 跳转到实现 |
| `K` | 悬停文档 |
| `<leader>rn` | 重命名符号 |
| `<leader>ca` | 代码操作 |
| `<leader>f` | 格式化文档 |
| `<leader>ds` | 文档符号 |
| `<leader>ws` | 工作区符号 |

### Java 专用

| 快捷键 | 功能 |
|--------|------|
| `<leader>jo` | 自动导入 |
| `<leader>jv` | 提取变量 |
| `<leader>jc` | 提取常量 |
| `<leader>jm` | 提取方法 |
| `<leader>jt` | 测试当前类 |
| `<leader>jn` | 测试最近方法 |

### Git

| 快捷键 | 功能 |
|--------|------|
| `<leader>gs` | Git 状态 |
| `<leader>gc` | Git 提交 |
| `<leader>gp` | Git 推送 |
| `<leader>gl` | Git 拉取 |
| `<leader>gd` | Git diff |
| `<leader>tg` | 打开 lazygit |
| `]c` / `[c` | 下一个/上一个 hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>tb` | 切换行 blame |

### 调试

| 快捷键 | 功能 |
|--------|------|
| `<F5>` | 继续/启动调试 |
| `<F9>` | 切换断点 |
| `<F10>` | 单步跳过 |
| `<F11>` | 单步进入 |
| `<F12>` | 单步跳出 |
| `<leader>du` | 切换调试 UI |

### 终端

| 快捷键 | 功能 |
|--------|------|
| `<C-\>` | 切换终端 |
| `<leader>t` | 切换终端 |
| `<leader>tg` | 打开 lazygit |

### 其他

| 快捷键 | 功能 |
|--------|------|
| `<leader>so` | 符号大纲 |
| `<leader>xx` | 问题列表 |
| `<leader>FF` | 手动格式化 |
| `gcc` | 切换行注释 |
| `gc` (visual) | 切换选中注释 |

## 特性

- **自动补全**: nvim-cmp 提供基于 LSP、代码片段、缓冲区的智能补全
- **语法高亮**: Treesitter 提供精准的语法高亮和代码折叠
- **LSP 支持**: 完整的 Java (jdtls)、Vue (vue_ls)、TypeScript 支持
- **代码格式化**: 自动格式化，支持 Prettier (前端) 和 google-java-format (Java)
- **Git 集成**: Gitsigns 显示修改标记，Fugitive 提供 Git 命令
- **调试支持**: DAP 框架，支持 Java 调试
- **文件浏览**: Neo-tree 提供类似 IDE 的文件树
- **模糊查找**: Telescope 快速搜索文件和文本
- **终端集成**: Toggleterm 内置终端
- **会话管理**: 自动保存和恢复工作会话

## 故障排除

### Java LSP 未启动

1. 确认 `jdtls` 已安装: `:Mason` -> 找到 jdtls -> `i`
2. 确认 `JAVA_HOME` 环境变量已设置
3. 检查 Java 版本: `java -version` (需要 >= 17)

### Vue/TypeScript 补全不工作

1. 确认 `vue_ls` 和 `vtsls` 已安装: `:Mason`
2. 在项目目录中确认 `node_modules` 已安装
3. 重启 Neovim

### 格式化失败

1. 确认 `prettier` 或 `google-java-format` 已安装
2. 检查 `:checkhealth mason`
3. 手动运行 `:ConformInfo` 查看格式化器状态
4. 运行 `:LintInfo` 查看 linter 状态
