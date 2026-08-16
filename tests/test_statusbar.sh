#!/usr/bin/env bash
# test_statusbar.sh — 隔离冒烟测试
# 用临时 CLAUDE_DIR 验证 install/verify/uninstall 全生命周期, 不碰真实 ~/.claude 配置。
# 覆盖: 双 JSON 后端(jq/python3)、保留已有配置、CLI 选项、--dry-run 无副作用、
#       server-url.txt 边界情形、statusbar 环境变量定制、git 远程超链接。
# 用法: bash tests/test_statusbar.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ESC=$'\033'; BEL=$'\a'

pass() { echo "  ✔ $1"; }
fail() { echo "  ✘ $1" >&2; exit 1; }

# ---------- 1/10 安装 (jq 后端) ----------
export CLAUDE_DIR="$TMP/claude-jq"
echo "==> 1/10 安装 (CLAUDE_DIR=$CLAUDE_DIR, jq 后端)"
bash "$ROOT/scripts/install.sh" >/dev/null || fail "install.sh 失败"
[ -f "$CLAUDE_DIR/statusbar-git-link.sh" ] || fail "状态栏脚本未部署";  pass "脚本已部署"
jq -e '.statusLine.type=="command" and (.statusLine.command|contains("statusbar-git-link.sh"))' "$CLAUDE_DIR/settings.json" >/dev/null || fail "statusLine 未配置"
pass "statusLine 已写入 settings.json"
[ -L "$CLAUDE_DIR/skills/claude-code-status" ] || fail "skill 软链接未注册";  pass "skill 软链接已注册"

# ---------- 2/10 幂等 + 保留已有配置键 ----------
echo "==> 2/10 安装幂等 + 保留已有配置"
jq '.theme="solarized" | .model="opulus"' "$CLAUDE_DIR/settings.json" > "$TMP/s2.json" && mv "$TMP/s2.json" "$CLAUDE_DIR/settings.json"
bash "$ROOT/scripts/install.sh" >/dev/null || fail "重复安装失败";  pass "重复安装 OK"
[ "$(jq -r '.statusLine.command' "$CLAUDE_DIR/settings.json")" = "bash $CLAUDE_DIR/statusbar-git-link.sh" ] || fail "statusLine 指向不符"
pass "statusLine command 正确"
jq -e '.theme=="solarized" and .model=="opulus"' "$CLAUDE_DIR/settings.json" >/dev/null || fail "已有配置键被覆盖"
pass "已有配置键(theme/model)保留"

# ---------- 3/10 状态栏实际输出 ----------
echo "==> 3/10 状态栏实际输出 (带 server-url.txt)"
PROJ="$TMP/proj"; mkdir -p "$PROJ"
printf 'web|http://192.168.1.83:8080\napi|http://192.168.1.83:8081\n' > "$PROJ/server-url.txt"
out="$(CLAUDE_PROJECT_DIR="$PROJ" bash "$CLAUDE_DIR/statusbar-git-link.sh")"
case "$out" in
  *"http://192.168.1.83:8080"*"http://192.168.1.83:8081"*) pass "两个 URL 入口都在输出中" ;;
  *) fail "输出不符合预期: $out" ;;
esac
[[ "$out" == *"${ESC}]8;;http://192.168.1.83:8080${BEL}http://192.168.1.83:8080${ESC}]8;;${BEL}"* ]] \
  && pass "URL 本体为超链接(链接文本=URL, 无前缀)" \
  || fail "超链接范围不符(应只包 URL): $out"
[[ "$out" == *"web: ${ESC}]8;;"* ]] \
  && pass "名称前缀在链接外(普通文本)" \
  || fail "名称前缀进入链接: $out"

# ---------- 4/10 边界: 纯 URL / 末行无换行 / 注释空行 / 空白修剪 ----------
echo "==> 4/10 server-url.txt 边界情形"
PROJ2="$TMP/proj2"; mkdir -p "$PROJ2"
printf '# 注释行\n\n  http://192.168.1.83:9000  \napi|  http://192.168.1.83:9001\nlast|http://192.168.1.83:9002' > "$PROJ2/server-url.txt"
out2="$(CLAUDE_PROJECT_DIR="$PROJ2" bash "$CLAUDE_DIR/statusbar-git-link.sh")"
case "$out2" in
  *"http://192.168.1.83:9000"*"http://192.168.1.83:9001"*"http://192.168.1.83:9002"*) pass "纯 URL/标签 URL/末行无换行 全部渲染" ;;
  *) fail "边界输出缺失: $out2" ;;
esac
[[ "$out2" != *"# 注释行"* && "$out2" != *"9000  "* ]] \
  && pass "注释行被忽略、URL 两侧空白被修剪" \
  || fail "注释/空白处理异常: $out2"
[[ "$out2" == *"api: "* ]] && pass "带名称条目正常" || fail "带名称条目缺失"

# ---------- 5/10 校验 + 卸载 (jq) ----------
echo "==> 5/10 verify + uninstall (jq)"
bash "$ROOT/scripts/verify.sh" >/dev/null || fail "verify.sh 失败";  pass "verify.sh 通过"
bash "$ROOT/scripts/uninstall.sh" >/dev/null || fail "uninstall.sh 失败"
jq -e 'has("statusLine")' "$CLAUDE_DIR/settings.json" >/dev/null && fail "卸载后 statusLine 仍在";  pass "statusLine 已移除"
jq -e '.theme=="solarized"' "$CLAUDE_DIR/settings.json" >/dev/null || fail "卸载误删已有配置";  pass "已有配置键保留"
[ -f "$CLAUDE_DIR/statusbar-git-link.sh" ] && fail "卸载后脚本仍在";  pass "脚本已删除"
[ -L "$CLAUDE_DIR/skills/claude-code-status" ] && fail "卸载后 skill 链接仍在";  pass "skill 软链接已移除"

# ---------- 6/10 python3 后端完整生命周期 ----------
export CLAUDE_DIR="$TMP/claude-py"
echo "==> 6/10 python3 后端完整生命周期"
export CCS_JSON_BACKEND=python3
bash "$ROOT/scripts/install.sh" >/dev/null || fail "[py] 安装失败"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["statusLine"]["command"]=="bash %s/statusbar-git-link.sh" % sys.argv[2]' "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR" || fail "[py] settings 写入异常"
pass "[py] 安装 + settings 写入"
bash "$ROOT/scripts/verify.sh" >/dev/null || fail "[py] verify 失败";  pass "[py] verify 通过"
bash "$ROOT/scripts/uninstall.sh" >/dev/null || fail "[py] 卸载失败"
python3 -c 'import json,sys; assert "statusLine" not in json.load(open(sys.argv[1]))' "$CLAUDE_DIR/settings.json" || fail "[py] 卸载后 statusLine 仍在"
pass "[py] 卸载成功"
unset CCS_JSON_BACKEND

# ---------- 7/10 statusbar 环境变量定制 ----------
# 7-9 节直接跑仓库里的脚本(不经安装, 与安装状态解耦)
echo "==> 7/10 statusbar 环境变量定制"
PROJ3="$TMP/proj3"; mkdir -p "$PROJ3"
printf '; 分号注释\nweb@http://192.168.1.83:7001\napi@http://192.168.1.83:7002\n' > "$PROJ3/urls.txt"
out3="$(STATUSBAR_URL_FILE=urls.txt STATUSBAR_URL_SEP='@' STATUSBAR_ENTRY_SEP=';;' STATUSBAR_COMMENT=';' CLAUDE_PROJECT_DIR="$PROJ3" bash "$ROOT/scripts/statusbar-git-link.sh")"
case "$out3" in
  *"http://192.168.1.83:7001"*";;"*"http://192.168.1.83:7002"*) pass "自定义 URL_FILE/URL_SEP/ENTRY_SEP 生效" ;;
  *) fail "环境变量定制未生效: $out3" ;;
esac
[[ "$out3" != *"分号注释"* ]] && pass "自定义注释字符生效" || fail "自定义注释字符未生效: $out3"

# ---------- 8/10 git 远程 → 超链接 ----------
echo "==> 8/10 git 远程转超链接"
if command -v git >/dev/null 2>&1; then
  PROJ4="$TMP/proj4"; mkdir -p "$PROJ4"; git -C "$PROJ4" init -q
  git -C "$PROJ4" remote add origin git@github.com:acme/demo.git
  out4="$(CLAUDE_PROJECT_DIR="$PROJ4" bash "$ROOT/scripts/statusbar-git-link.sh")"
  [[ "$out4" == *"${ESC}]8;;https://github.com/acme/demo${BEL}proj4${ESC}]8;;${BEL}"* ]] \
    && pass "git@ SSH 远程 → https 超链接(项目名可点击)" \
    || fail "git 超链接不符: $out4"
else
  pass "git 不可用, 跳过"
fi

# ---------- 9/10 无 server-url.txt 时正常 ----------
echo "==> 9/10 无 server-url.txt 时输出正常"
PROJ5="$TMP/proj5"; mkdir -p "$PROJ5"
out5="$(CLAUDE_PROJECT_DIR="$PROJ5" bash "$ROOT/scripts/statusbar-git-link.sh")"
[[ "$out5" == *"proj5"* && "$out5" != *" | "* ]] && pass "无 URL 文件时仅显示主机名+项目名" || fail "无 URL 文件输出异常: $out5"

# ---------- 10/10 CLI 选项与 --dry-run 无副作用 ----------
echo "==> 10/10 CLI 选项与 --dry-run 无副作用"
export CLAUDE_DIR="$TMP/claude-cli"
bash "$ROOT/scripts/install.sh" --version | grep -q 'claude-code-status 1.1.0' || fail "--version 输出异常"
pass "--version 输出版本号"
bash "$ROOT/scripts/install.sh" --help | grep -q '用法' || fail "--help 未输出用法"
pass "--help 输出用法"
# dry-run 安装: 不产生任何文件
bash "$ROOT/scripts/install.sh" --dry-run >/dev/null || fail "dry-run 安装失败"
[ -e "$CLAUDE_DIR" ] && fail "dry-run 安装产生了文件/目录" || pass "dry-run 安装无副作用"
# 真实安装后 dry-run 卸载: 不动任何东西
bash "$ROOT/scripts/install.sh" >/dev/null || fail "真实安装失败"
bash "$ROOT/scripts/uninstall.sh" --dry-run >/dev/null || fail "dry-run 卸载失败"
[ -f "$CLAUDE_DIR/statusbar-git-link.sh" ] || fail "dry-run 卸载误删脚本"
jq -e 'has("statusLine")' "$CLAUDE_DIR/settings.json" >/dev/null || fail "dry-run 卸载误删 statusLine"
pass "dry-run 卸载无副作用"
# 未知参数告警但不失败
bash "$ROOT/scripts/install.sh" --bogus >/dev/null 2>&1 || fail "未知参数不应导致失败"
pass "未知参数仅告警不失败"

echo ""
echo "✔ 冒烟测试全部通过 (10/10)"
