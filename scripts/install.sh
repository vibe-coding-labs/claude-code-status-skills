#!/usr/bin/env bash
# install.sh — 安装/更新 Claude Code 状态栏(statusline)
# 步骤: 1) 部署状态栏脚本到 ~/.claude/  2) 写入 settings.json 的 statusLine
#       3) 注册本 skill 到用户级 skills(软链接, 仓库更新即 skill 更新)
# 用法: bash scripts/install.sh
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude), 便于测试或非默认安装

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSBAR_TARGET="$CLAUDE_DIR/statusbar-git-link.sh"
SKILL_NAME="claude-code-status"

if ! command -v jq >/dev/null 2>&1; then
  echo "✘ 需要 jq 来合并 settings.json，请先安装 (sudo apt install jq)" >&2
  exit 1
fi

echo "==> 1/3 部署状态栏脚本 → $STATUSBAR_TARGET"
install -D -m 0755 "$REPO_DIR/scripts/statusbar-git-link.sh" "$STATUSBAR_TARGET"

echo "==> 2/3 写入 statusLine 配置 → $SETTINGS (保留其他配置)"
CMD="bash $STATUSBAR_TARGET"
if [ -f "$SETTINGS" ]; then
  tmp="$(mktemp)"
  if jq --arg cmd "$CMD" '.statusLine = {type:"command", command:$cmd}' "$SETTINGS" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$SETTINGS"
  else
    echo "⚠ settings.json 无法被 jq 解析(含注释?), 跳过配置; 请手动添加 statusLine 项" >&2
    rm -f "$tmp"
  fi
else
  mkdir -p "$CLAUDE_DIR"
  printf '{\n  "statusLine": { "type": "command", "command": "%s" }\n}\n' "$CMD" > "$SETTINGS"
fi

echo "==> 3/3 注册 skill → $CLAUDE_DIR/skills/$SKILL_NAME (软链接)"
mkdir -p "$CLAUDE_DIR/skills"
ln -sfn "$REPO_DIR" "$CLAUDE_DIR/skills/$SKILL_NAME"

echo ""
echo "✔ 安装完成。新开 Claude Code 会话即可看到状态栏:"
echo "   <主机名>: <项目名> | <服务名>: http://IP:PORT"
echo ""
echo "  为项目声明服务 URL: 在项目根目录创建 server-url.txt"
echo "  格式(每行一个入口, # 注释/空行忽略):"
echo "    backend|http://IP:PORT"
echo "    http://IP:PORT"
echo "  校验: bash scripts/verify.sh | 卸载: bash scripts/uninstall.sh"
