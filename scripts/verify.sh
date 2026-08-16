#!/usr/bin/env bash
# verify.sh — 校验 Claude Code 状态栏安装是否正常
# 检查: 1) 脚本存在+语法  2) settings.json statusLine 配置  3) 输出样例
# 用法: bash scripts/verify.sh
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSBAR_TARGET="$CLAUDE_DIR/statusbar-git-link.sh"
fail=0

echo "==> 1/3 脚本存在与语法"
if [ -f "$STATUSBAR_TARGET" ] && bash -n "$STATUSBAR_TARGET" 2>/dev/null; then
  echo "  ✔ $STATUSBAR_TARGET 存在且语法正确"
else
  echo "  ✘ 脚本缺失或语法错误"
  fail=1
fi

echo "==> 2/3 settings.json 的 statusLine 配置"
if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ] && \
   jq -e --arg cmd "bash $STATUSBAR_TARGET" '.statusLine.type=="command" and .statusLine.command==$cmd' "$SETTINGS" >/dev/null 2>&1; then
  echo "  ✔ statusLine 已配置且 command 指向正确脚本"
else
  echo "  ✘ statusLine 未配置或 command 不匹配 (期望: bash $STATUSBAR_TARGET)"
  fail=1
fi

echo "==> 3/3 输出样例(带 server-url.txt)"
tmp="$(mktemp -d)"
printf 'web|http://192.168.1.83:8080\n' > "$tmp/server-url.txt"
out="$(CLAUDE_PROJECT_DIR="$tmp" bash "$STATUSBAR_TARGET" 2>/dev/null || true)"
rm -rf "$tmp"
echo "  样例: $out"
case "$out" in
  *"http://192.168.1.83:8080"*) echo "  ✔ 样例输出包含声明的 URL" ;;
  *) echo "  ✘ 样例输出缺少 URL (脚本可能未按 server-url.txt 约定工作)"; fail=1 ;;
esac

echo ""
if [ "$fail" = 0 ]; then
  echo "✔ 校验通过"
else
  echo "✘ 校验失败, 请重新运行: bash scripts/install.sh" >&2
  exit 1
fi
