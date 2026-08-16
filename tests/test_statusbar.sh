#!/usr/bin/env bash
# test_statusbar.sh — 隔离冒烟测试
# 用临时 CLAUDE_DIR 验证 install/verify/uninstall 全生命周期，不碰真实 ~/.claude 配置。
# 用法: bash tests/test_statusbar.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_DIR="$TMP/claude"

pass() { echo "  ✔ $1"; }
fail() { echo "  ✘ $1" >&2; exit 1; }

echo "==> 1/5 安装 (CLAUDE_DIR=$CLAUDE_DIR)"
bash "$ROOT/scripts/install.sh" >/dev/null
[ -f "$CLAUDE_DIR/statusbar-git-link.sh" ] || fail "状态栏脚本未部署"
pass "脚本已部署"
jq -e '.statusLine.type=="command" and (.statusLine.command|contains("statusbar-git-link.sh"))' "$CLAUDE_DIR/settings.json" >/dev/null || fail "statusLine 未配置"
pass "statusLine 已写入 settings.json"
[ -L "$CLAUDE_DIR/skills/claude-code-status" ] || fail "skill 软链接未注册"
pass "skill 软链接已注册"

echo "==> 2/5 安装幂等 (重复安装不报错)"
bash "$ROOT/scripts/install.sh" >/dev/null || fail "重复安装失败"
pass "重复安装 OK"
[ "$(jq -r '.statusLine.command' "$CLAUDE_DIR/settings.json")" = "bash $CLAUDE_DIR/statusbar-git-link.sh" ] || fail "statusLine 指向不符"
pass "statusLine command 正确"

echo "==> 3/5 状态栏实际输出 (带 server-url.txt)"
PROJ="$TMP/proj"; mkdir -p "$PROJ"
printf 'web|http://192.168.1.83:8080\napi|http://192.168.1.83:8081\n' > "$PROJ/server-url.txt"
out="$(CLAUDE_PROJECT_DIR="$PROJ" bash "$CLAUDE_DIR/statusbar-git-link.sh")"
ESC=$'\033'; BEL=$'\a'
# 两个 URL 入口都渲染在输出中(名称与 URL 之间隔着 OSC8 序列, 故分别检查)
case "$out" in
  *"http://192.168.1.83:8080"*"http://192.168.1.83:8081"*) pass "两个 URL 入口都在输出中" ;;
  *) fail "输出不符合预期: $out" ;;
esac
# 超链接只包裹 URL 本体: OSC8 序列 [ESC]8;;URL BEL URL ESC]8;; BEL]
# 链接内显示文本 = URL 本身(无 "名称: " 前缀)
[[ "$out" == *"${ESC}]8;;http://192.168.1.83:8080${BEL}http://192.168.1.83:8080${ESC}]8;;${BEL}"* ]] \
  && pass "URL 本体为超链接(链接文本=URL, 无前缀)" \
  || fail "超链接范围不符(应只包 URL): $out"
# 名称前缀在链接外: "web: " 紧跟链接起始序列
[[ "$out" == *"web: ${ESC}]8;;"* ]] \
  && pass "名称前缀在链接外(普通文本)" \
  || fail "名称前缀进入链接: $out"

echo "==> 4/5 校验"
bash "$ROOT/scripts/verify.sh" >/dev/null || fail "verify.sh 失败"
pass "verify.sh 通过"

echo "==> 5/5 卸载"
bash "$ROOT/scripts/uninstall.sh" >/dev/null || fail "uninstall.sh 失败"
jq -e 'has("statusLine")' "$CLAUDE_DIR/settings.json" >/dev/null && fail "卸载后 statusLine 仍在"
pass "statusLine 已移除"
[ -f "$CLAUDE_DIR/statusbar-git-link.sh" ] && fail "卸载后脚本仍在"
pass "脚本已删除"
[ -L "$CLAUDE_DIR/skills/claude-code-status" ] && fail "卸载后 skill 链接仍在"
pass "skill 软链接已移除"

echo ""
echo "✔ 冒烟测试全部通过"
