#!/usr/bin/env bash
# status.sh — 查看 Claude Code 状态栏安装状态(只读)
# 薄封装: 全部逻辑在 lib.sh, 此处仅解析 CLI 并调用主流程。
# 显示: 脚本存在/语法/与仓库同步、settings.json statusLine、skill 软链接。
# 用法: bash scripts/status.sh [--help|--version|--verbose]
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ccs_cli_parse "$CCS_USAGE_STATUS" "$@"
ccs_status_main
