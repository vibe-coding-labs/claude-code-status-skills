---
name: claude-code-status
description: 安装、配置、校验、卸载 Claude Code 状态栏(statusline)。状态栏显示 主机名: 项目名(git 仓库链接) | 服务名: http://IP:PORT(局域网可访问 URL, 可点击超链接)，URL 通过项目根目录 server-url.txt 约定声明、支持多入口与名称标签。当用户想安装/配置/查看/卸载 Claude Code 状态栏，或在新机器上部署状态栏，或询问状态栏如何显示项目与服务信息时使用。
---

# Claude Code 状态栏 (statusline)

管理 Claude Code 状态栏的安装、配置、校验与卸载。

## 状态栏展示内容

`<主机名>: <项目名>(git 仓库链接, 可点击) | <服务名>: http://IP:PORT(局域网服务, 可点击)`

- **git 仓库链接**：自动从项目 `git remote` 解析（SSH/HTTPS 形式均支持）。
- **局域网服务 URL**：由项目根目录的 `server-url.txt` 声明，每行一个入口。

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
- 写入 `~/.claude/settings.json` 的 `statusLine` 配置（用 jq 合并，保留其余配置；jq 不可用时会提示手动配置）
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

## 环境变量

所有脚本支持 `CLAUDE_DIR` 覆盖（默认 `~/.claude`），用于非默认安装或测试隔离。示例：
Run: `CLAUDE_DIR=/tmp/test-claude bash scripts/install.sh`
