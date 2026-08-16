#!/usr/bin/env bash
# verify.sh — 校验 Claude Code 状态栏安装是否正常
# 薄封装: 全部逻辑在 lib.sh, 此处仅解析 CLI 并调用主流程。
# 检查: 1) 脚本存在+语法  2) settings.json statusLine 配置  3) 输出样例
# 用法: bash scripts/verify.sh [--help|--version|--verbose|--dry-run]
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ccs_cli_parse "$CCS_USAGE_VERIFY" "$@"
ccs_verify_main
