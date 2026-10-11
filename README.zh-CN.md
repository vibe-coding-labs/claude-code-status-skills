# Claude Code 状态栏

[English](README.md) | [简体中文](README.zh-CN.md)

一个可安装、可配置的 [Claude Code](https://claude.com/claude-code) 状态栏（statusline），封装为一个 skill。状态栏展示**当前模型 ID**、**主机名**、**可点击的 git 仓库链接**和**可点击的局域网服务 URL**，安装、配置、校验与卸载都由这一个 skill 完成。

## 效果

```
claude-opus-5 | local-server-002: PaiMian | backend: http://192.168.1.83:30816 | pc: http://192.168.1.83:8080
```

- `claude-opus-5` — 当前会话正在使用的模型 ID，取自 Claude Code 传给 statusline 命令的会话 JSON 的 `model.id`；取不到时该段省略。
- `PaiMian` — 可点击的 git 仓库链接（自动解析 `git remote`，SSH 与 HTTPS 都支持）。
- `backend: http://…` — 可点击的局域网服务 URL（由 `server-url.txt` 声明，仅 URL 本体为超链接，名称前缀为普通文本）。

## 安装

### 方式一：Claude Code marketplace（推荐）

在 Claude Code 会话里：

```text
/plugin marketplace add vibe-coding-labs/claude-code-status-skills
/plugin install claude-code-status@claude-code-status-skills
```

或在终端里：

```bash
claude plugin marketplace add vibe-coding-labs/claude-code-status-skills
claude plugin install claude-code-status@claude-code-status-skills
```

这一步注册 skill。状态栏本身由安装脚本激活（见下一节），skill 会替你执行它——新开一个会话后让 Claude 安装状态栏，或直接运行脚本即可。

### 方式二：安装脚本

```bash
git clone https://github.com/vibe-coding-labs/claude-code-status-skills.git
cd claude-code-status-skills
bash scripts/install.sh    # 部署脚本 + 合并 settings.json + 注册 skill
bash scripts/verify.sh     # 校验结果
```

新开一个 Claude Code 会话，状态栏即生效。

### 为项目声明服务 URL

在项目根目录创建 `server-url.txt`（或用 `/server-url` skill 自动生成）。状态栏 URL 是为了方便跳转，只需收录**首页型**入口（前端页面、管理后台、文档站等），纯后端 API 的 base URL 通常不必收录：

```text
pc|http://192.168.1.83:8080
admin|http://192.168.1.83:8080/admin
```

之后状态栏即显示 `pc: http://192.168.1.83:8080`（可点击）。项目是 git 仓库时，建议把 `server-url.txt` 加入 `.gitignore`，避免内网地址入库。

## 使用方式

| 场景 | 命令 |
|------|------|
| 安装 / 更新 | `bash scripts/install.sh` |
| 校验（含与仓库同步检查） | `bash scripts/verify.sh` |
| 查看安装状态（只读） | `bash scripts/status.sh` |
| 卸载 | `bash scripts/uninstall.sh` |
| 演练（不实际改动） | 上述命令追加 `--dry-run` |
| 为项目配置 URL | 项目根目录建 `server-url.txt` |

### `server-url.txt` 格式

每行一个入口，`#` 开头为注释、空行忽略、URL 不得含 `|`：

```text
# 服务入口 (更新于 2026-08-17)
pc|http://192.168.1.83:8080
admin|http://192.168.1.83:8080/admin
doc|http://192.168.1.83:8081/swagger-ui.html
```

- `名称|http://IP:PORT` — 带名称（推荐），状态栏显示 `名称: URL`。
- `http://IP:PORT` — 不带名称，状态栏直接显示 URL。

收录原则：

| 类型 | 举例 | 是否收录 |
|------|------|----------|
| 前端页面 / 管理后台 | Vite/Webpack/Next 开发服务器、admin 后台、Nginx 统一入口 | 收录 |
| 接口文档 / 可视化调试页 | Swagger UI、`/doc.html`、GraphQL Playground | 收录（收录文档路径本身，而非裸 API 根路径） |
| 纯后端 API base URL | Spring Boot / Express / FastAPI 的 `/api` 根路径 | 默认不收录 |
| 健康检查 / metrics / WebSocket / gRPC | `/actuator`、`/health`、纯协议端口 | 不收录 |

单个项目一般 1~3 个入口即可。快速判断：`curl -s -o /dev/null -w '%{content_type}\n' http://IP:PORT/`，返回 `text/html` 多半是页面（收录），返回 `application/json` 或连接失败多半是接口（不收录）。

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
| `STATUSBAR_URL_FILE` | 替代 `server-url.txt` 的文件名 | `server-url.txt` |
| `STATUSBAR_URL_SEP` | 名称与 URL 的分隔符 | `\|` |
| `STATUSBAR_ENTRY_SEP` | 多个 URL 条目的间隔符 | ` \| ` |
| `STATUSBAR_COMMENT` | 注释行前缀 | `#` |
| `CCS_JSON_BACKEND` | 强制 JSON 后端：`jq` / `python3`（空为自动） | 自动 |

`STATUSBAR_*` 影响渲染行为，可直接在 statusline 命令前注入：

```bash
STATUSBAR_URL_FILE=urls.txt STATUSBAR_ENTRY_SEP="  " bash ~/.claude/statusbar-git-link.sh
```

## 目录结构

```
claude-code-status-skills/
├── .claude-plugin/
│   ├── marketplace.json        # marketplace 清单（支持 /plugin marketplace add）
│   └── plugin.json             # 插件清单
├── SKILL.md                    # skill 入口（Claude 按此执行安装/配置/校验/卸载）
├── scripts/
│   ├── lib.sh                  # 公共库：配置/日志/JSON 后端/settings 操作/CLI 解析
│   ├── install.sh              # 安装：部署脚本 + 合并 settings.json + 注册 skill
│   ├── uninstall.sh            # 卸载：移除配置/脚本/skill 链接
│   ├── verify.sh               # 校验：脚本语法 + 配置 + 同步 + 输出样例
│   ├── status.sh               # 状态：只读总览（脚本/配置/软链接/与仓库同步）
│   └── statusbar-git-link.sh   # 状态栏脚本本体（OSC 8 超链接渲染，自包含）
└── tests/
    └── test_statusbar.sh       # 隔离冒烟测试（12 节，临时 CLAUDE_DIR，不碰真实配置）
```

## 设计说明

- **模块化**：三个管理脚本逻辑全部收敛到 `scripts/lib.sh`，各自仅剩约 10 行薄封装，消除重复代码。
- **JSON 双后端**：`settings.json` 的读写优先用 `jq`，缺失时自动回退 `python3`，两者都不可用才报错；可经 `CCS_JSON_BACKEND` 强制指定。
- **零风险安装**：所有写操作走 `ccs_run`，支持 `--dry-run` 演练；`settings.json` 合并保留其余键，卸载只移除 `statusLine`。
- **状态可见**：`verify.sh` 与 `status.sh` 都会用 `cmp` 对比已装脚本与仓库版本，漂移时提示重跑 install；`status.sh` 为只读总览，不改动任何文件。
- **状态栏脚本自包含**：运行时被复制到 `~/.claude/`，不依赖仓库，同时保持可配置（`STATUSBAR_*` 环境变量均有默认值）。
- **边界健壮**：`server-url.txt` 支持纯 URL 与 `名称|URL` 两种行、`#` 注释、空行、两侧空白修剪、末行无换行；从 stdin 读会话 JSON 带超时，statusline 管道写完不关闭也不会让刷新挂起；所有命令对 `set -euo pipefail` 友好。

## 原理

- `settings.json` 的 `statusLine` 指向 `statusbar-git-link.sh`。脚本用 `CLAUDE_PROJECT_DIR` 定位项目根目录（缺失时回退到 stdin JSON 的 `workspace.project_dir`），读取 `server-url.txt` 并以 OSC 8 超链接渲染。
- 当前模型 ID 取自 Claude Code 经 stdin 传入的会话 JSON 的 `model.id`，解析优先 `jq`，其次 `python3`，最后 `sed` 兜底。
- skill 本体通过软链接注册到 `~/.claude/skills/`，仓库更新即生效。

## License

MIT
