#!/usr/bin/env bash
# uninstall.sh — 卸载 Claude Code 状态栏(statusline)
# 步骤: 1) 从 settings.json 移除 statusLine  2) 删除状态栏脚本  3) 移除 skill 软链接
# 用法: bash scripts/uninstall.sh
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSBAR_TARGET="$CLAUDE_DIR/statusbar-git-link.sh"
SKILL_NAME="claude-code-status"

echo "==> 1/3 从 settings.json 移除 statusLine"
if [ -f "$SETTINGS" ]; then
  if command -v jq >/dev/null 2>&1 && jq -e 'has("statusLine")' "$SETTINGS" >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq 'del(.statusLine)' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
    echo "  ✔ 已移除 statusLine (其余配置保留)"
  else
    echo "  - settings.json 无 statusLine 或 jq 不可用, 跳过"
  fi
else
  echo "  - settings.json 不存在, 跳过"
fi

echo "==> 2/3 删除状态栏脚本"
if [ -f "$STATUSBAR_TARGET" ]; then
  rm -f "$STATUSBAR_TARGET"
  echo "  ✔ 已删除 $STATUSBAR_TARGET"
else
  echo "  - 脚本不存在, 跳过"
fi

echo "==> 3/3 移除 skill 软链接(仅当指向本仓库)"
SKILL_LINK="$CLAUDE_DIR/skills/$SKILL_NAME"
if [ -L "$SKILL_LINK" ]; then
  target="$(readlink "$SKILL_LINK")"
  if [ "$target" = "$REPO_DIR" ]; then
    rm -f "$SKILL_LINK"
    echo "  ✔ 已移除 $SKILL_LINK"
  else
    echo "  - 软链接指向 $target (非本仓库), 未动"
  fi
else
  echo "  - 无 skill 软链接, 跳过"
fi

echo ""
echo "✔ 卸载完成。状态栏已恢复默认, 新会话生效。"
echo "  提示: 项目根目录已有的 server-url.txt 不受影响, 可按需删除。"
