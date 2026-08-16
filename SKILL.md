---
name: claude-code-status
description: 安装、配置、校验、卸载 Claude Code 状态栏(statusline)。状态栏显示 主机名: 项目名(git 仓库链接) | 服务名: http://IP:PORT(局域网可访问 URL, 可点击超链接)，URL 通过项目根目录 server-url.txt 约定声明、支持多入口与名称标签。当用户想安装/配置/查看/卸载 Claude Code 状态栏，或在新机器上部署状态栏，或询问状态栏如何显示项目与服务信息时使用。
---

# Claude Code 状态栏 (statusline)

管理 Claude Code 状态栏的安装、配置、校验与卸载。

## 状态栏展示内容

`<主机名>: <项目名>(git 仓库链接, 可点击) | <服务名>: http://IP:PORT(局域网服务, 可点击)`

- **git 仓库链接**：自动从项目 `git remote` 解析（SSH/HTTPS 形式均支持）。
- **局域网服务 URL**：由项目根目录的 `server-url.txt` 声明，每行一个入口；仅 URL 本体为超链接，名称前缀为普通文本。

## server-url.txt 格式（项目级配置）

每行一个入口，`#` 开头为注释、空行忽略、URL 不得含 `|`：

```text
# 服务入口 (更新于 2026-08-17)
backend|http://192.168.1.83:30816
pc|http://192.168.1.83:8080
http://192.168.1.83:9000
```

- `名称|http://IP:PORT` — 带名称（推荐），状态栏显示 `名称: URL`
- `http://IP:PORT` — 不带名称，状态栏直接显示 URL
- 项目是 git 仓库时，建议将 `server-url.txt` 加入 `.gitignore` 避免内网地址泄露

## 操作

所有命令从本 skill 仓库根目录执行（`scripts/` 在此目录下）。

### 1. 安装 / 更新
Run: `bash scripts/install.sh`

执行内容：
- 部署状态栏脚本到 `~/.claude/statusbar-git-link.sh`
- 写入 `~/.claude/settings.json` 的 `statusLine` 配置（保留其余键；JSON 读写用 jq，缺失自动回退 python3）
- 将本仓库软链接注册到用户级 skills（`~/.claude/skills/claude-code-status`），仓库更新即 skill 更新
- 完成后**需新开 Claude Code 会话**才生效

### 2. 为项目配置服务 URL
在项目根目录创建 `server-url.txt`（格式见上），或调用 `/server-url` skill 自动探测本机 IP 与监听端口生成。

### 3. 校验安装
Run: `bash scripts/verify.sh`
- 检查脚本存在/语法、`settings.json` 配置、输出样例

### 4. 卸载
Run: `bash scripts/uninstall.sh`
- 从 `settings.json` 移除 `statusLine`、删除状态栏脚本、移除 skill 软链接（其他配置与 server-url.txt 不受影响）

## 通用选项

三个管理脚本均支持：

| 选项 | 说明 |
|------|------|
| `--help` / `-h` | 显示用法 |
| `--version` / `-V` | 显示版本号 |
| `--verbose` / `-v` | 输出 debug 日志 |
| `--dry-run` | 演练模式，不实际改动（安装/卸载前预览操作） |

## 环境变量

| 变量 | 说明 | 默认 |
|------|------|------|
| `CLAUDE_DIR` | Claude Code 配置根目录（测试隔离常用） | `~/.claude` |
| `STATUSBAR_URL_FILE` | `server-url.txt` 的文件名 | `server-url.txt` |
| `STATUSBAR_URL_SEP` | 名称与 URL 的分隔符 | `\|` |
| `STATUSBAR_ENTRY_SEP` | 多个 URL 条目的间隔符 | ` \| ` |
| `STATUSBAR_COMMENT` | 注释行前缀 | `#` |
| `CCS_JSON_BACKEND` | 强制 JSON 后端：`jq` / `python3`（空为自动） | 自动 |

示例：
Run: `CLAUDE_DIR=/tmp/test-claude bash scripts/install.sh`
Run: `bash scripts/install.sh --dry-run`
