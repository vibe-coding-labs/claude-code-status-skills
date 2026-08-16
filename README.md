# Claude Code 状态栏 Skill

一个可安装、可配置的 [Claude Code](https://claude.com/claude-code) 状态栏（statusline）封装。状态栏展示 **主机名 / 项目 git 链接 / 局域网服务 URL**，通过一个 skill 完成安装、配置、校验与卸载。

## 效果

```
local-server-002: PaiMian | backend: http://192.168.1.83:30816 | pc: http://192.168.1.83:8080
```

- `PaiMian` → 可点击的 git 仓库链接（自动解析 `git remote`）
- `backend: http://…` → 可点击的局域网服务 URL（由 `server-url.txt` 声明，仅 URL 本体为超链接，名称前缀为普通文本）

## 快速开始

```bash
# 1. 克隆仓库
git clone <this-repo> && cd claude-code-status-skills

# 2. 安装（部署脚本 + 配置 settings.json + 注册 skill）
bash scripts/install.sh

# 3. 校验
bash scripts/verify.sh

# 4. 新开 Claude Code 会话 → 状态栏生效
```

为项目声明服务 URL：在项目根目录创建 `server-url.txt`：

```text
backend|http://192.168.1.83:30816
pc|http://192.168.1.83:8080
```

之后状态栏即显示 `backend: http://192.168.1.83:30816`（可点击）。

## 目录结构

```
claude-code-status-skills/
├── SKILL.md                    # skill 入口（Claude 按此执行安装/配置/校验/卸载）
├── scripts/
│   ├── lib.sh                  # 公共库：配置/日志/JSON 后端/settings 操作/CLI 解析
│   ├── install.sh              # 安装：薄封装 + 主流程（部署脚本 + 合并 settings.json + 注册 skill）
│   ├── uninstall.sh            # 卸载：薄封装 + 主流程（移除配置/脚本/skill 链接）
│   ├── verify.sh               # 校验：薄封装 + 主流程（脚本语法 + 配置 + 输出样例）
│   └── statusbar-git-link.sh   # 状态栏脚本本体（OSC8 超链接渲染，自包含）
└── tests/
    └── test_statusbar.sh       # 隔离冒烟测试（10 节，临时 CLAUDE_DIR，不碰真实配置）
```

## 使用方式

| 场景 | 命令 |
|------|------|
| 安装 / 更新 | `bash scripts/install.sh` |
| 校验 | `bash scripts/verify.sh` |
| 卸载 | `bash scripts/uninstall.sh` |
| 演练（不实际改动） | 上述命令追加 `--dry-run` |
| 为项目配置 URL | 项目根目录建 `server-url.txt`（或 `/server-url` skill） |

### 通用 CLI 选项

| 选项 | 说明 |
|------|------|
| `--help` / `-h` | 显示用法 |
| `--version` / `-V` | 显示版本号 |
| `--verbose` / `-v` | 输出 debug 日志 |
| `--dry-run` | 演练模式，只打印将执行的操作，不实际改动 |

### 环境变量

| 变量 | 说明 | 默认 |
|------|------|------|
| `CLAUDE_DIR` | Claude Code 配置根目录（测试隔离常用） | `~/.claude` |
| `STATUSBAR_URL_FILE` | `server-url.txt` 的文件名 | `server-url.txt` |
| `STATUSBAR_URL_SEP` | 名称与 URL 的分隔符 | `\|` |
| `STATUSBAR_ENTRY_SEP` | 多个 URL 条目的间隔符 | ` \| ` |
| `STATUSBAR_COMMENT` | 注释行前缀 | `#` |
| `CCS_JSON_BACKEND` | 强制 JSON 后端：`jq` / `python3`（空为自动） | 自动 |

`STATUSBAR_*` 影响的是状态栏脚本的渲染行为，可直接在 statusline 命令前注入，例如：
```bash
STATUSBAR_URL_FILE=urls.txt STATUSBAR_ENTRY_SEP="  " bash ~/.claude/statusbar-git-link.sh
```

## 设计说明

- **模块化**：三个管理脚本逻辑全部收敛到 `scripts/lib.sh`，各自仅剩 ~10 行薄封装（source lib + CLI 解析 + 调主流程），消除重复代码。
- **JSON 双后端**：`settings.json` 的读写优先用 `jq`，缺失时自动回退 `python3`，两者都不可用才报错；可经 `CCS_JSON_BACKEND` 强制指定。
- **零风险安装**：所有写操作走 `ccs_run`，支持 `--dry-run` 演练；`settings.json` 合并保留其余键，卸载只移除 `statusLine`。
- **状态栏脚本自包含**：运行时被复制到 `~/.claude/`，不依赖仓库，但保持可配置（`STATUSBAR_*` 环境变量均有默认值）。
- **边界健壮**：`server-url.txt` 支持纯 URL 与 `名称|URL` 两种行、`#` 注释、空行、两侧空白修剪、末行无换行；所有命令对 `set -euo pipefail` 友好（避免 `&&` 简写在 `set -e` 下的陷阱）。

## 原理

- `settings.json` 的 `statusLine` 指向 `statusbar-git-link.sh`，脚本用 `CLAUDE_PROJECT_DIR` 定位项目根目录，读取 `server-url.txt` 并以 OSC 8 超链接渲染。
- skill 本体通过软链接注册到 `~/.claude/skills/`，仓库更新即生效。

## License

MIT
