#!/usr/bin/env bash
# install.sh — 安装/更新 Claude Code 状态栏(statusline)
# 薄封装: 全部逻辑在 lib.sh, 此处仅解析 CLI 并调用主流程。
# 步骤: 1) 部署状态栏脚本  2) 写入 settings.json 的 statusLine  3) 注册 skill 软链接
# 用法: bash scripts/install.sh [--help|--version|--verbose|--dry-run]
# 覆盖: CLAUDE_DIR=自定义配置目录(默认 ~/.claude)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ccs_cli_parse "$CCS_USAGE_INSTALL" "$@"
ccs_install_main
