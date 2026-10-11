#!/usr/bin/env bash
# lib.sh — claude-code-status skill 公共库
# 被 scripts/install.sh、scripts/uninstall.sh、scripts/verify.sh source 使用。
#
# 模块化约定:
#   - 所有配置可经环境变量覆盖, 便于测试/非默认安装
#   - JSON 操作双后端: jq 优先, python3 兜底, 均缺失时报错
#   - 统一日志: log_info/log_warn/log_error/log_debug(VERBOSE=1 显示)
#   - 所有写操作经 ccs_run, 支持 DRY_RUN=1 演练
#
# 变量/函数前缀: CCS_(Claude Code Status)

# ---------- 配置(环境变量可覆盖) ----------
: "${CLAUDE_DIR:=${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"   # 配置根目录
: "${STATUSBAR_SCRIPT_NAME:=statusbar-git-link.sh}"       # 状态栏脚本文件名
: "${SKILL_NAME:=claude-code-status}"                     # skill 目录名
: "${VERBOSE:=0}"                                         # 1 = 显示 debug 日志
: "${DRY_RUN:=0}"                                         # 1 = 演练, 不实际改动
: "${CCS_JSON_BACKEND:=}"                                 # 强制 JSON 后端: jq|python3|空(自动)

# 仓库根目录 = lib.sh 所在 scripts/ 的上一级
CCS_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CCS_VERSION="1.2.0"

CCS_STATUSBAR_SOURCE="$CCS_REPO_DIR/scripts/$STATUSBAR_SCRIPT_NAME"
CCS_STATUSBAR_TARGET="$CLAUDE_DIR/$STATUSBAR_SCRIPT_NAME"
CCS_SETTINGS="$CLAUDE_DIR/settings.json"
CCS_SKILL_LINK="$CLAUDE_DIR/skills/$SKILL_NAME"

# ---------- 日志 ----------
ccs_log_info()  { printf '\033[1;32m[info ]\033[0m %s\n' "$*"; }
ccs_log_warn()  { printf '\033[1;33m[warn ]\033[0m %s\n' "$*" >&2; }
ccs_log_error() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
ccs_log_debug() { # 仅在 VERBOSE=1 时输出; 用 if 而非 && 简写, 避免 set -e 下返回非零
  if [ "$VERBOSE" = 1 ]; then
    printf '\033[1;36m[debug]\033[0m %s\n' "$*" >&2
  fi
}

# ---------- 前置检查 ----------
ccs_require_cmd() { # 检查命令存在, 缺失则报错返回 1
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    ccs_log_error "缺少依赖命令: $name"
    return 1
  fi
  return 0
}

# ---------- JSON 后端探测 ----------
ccs_json_backend() { # 输出: jq | python3 | none
  if [ -n "$CCS_JSON_BACKEND" ]; then
    printf '%s\n' "$CCS_JSON_BACKEND"; return 0
  fi
  if command -v jq >/dev/null 2>&1; then printf 'jq\n'
  elif command -v python3 >/dev/null 2>&1; then printf 'python3\n'
  else printf 'none\n'; fi
}

# ---------- settings.json 操作 ----------
# 写入 statusLine(保留其余键); settings.json 不存在则创建。
# 用法: ccs_settings_set_statusline "bash /abs/path/statusbar-git-link.sh"
ccs_settings_set_statusline() {
  local cmd="$1"
  if [ "$DRY_RUN" = 1 ]; then
    ccs_log_info "[dry-run] 将写入 statusLine → $CCS_SETTINGS"
    return 0
  fi
  mkdir -p "$(dirname "$CCS_SETTINGS")"
  case "$(ccs_json_backend)" in
    jq)
      if [ -f "$CCS_SETTINGS" ]; then
        local tmp; tmp="$(mktemp)"
        if jq --arg cmd "$cmd" '.statusLine = {type:"command", command:$cmd}' "$CCS_SETTINGS" > "$tmp" 2>/dev/null; then
          mv "$tmp" "$CCS_SETTINGS"
        else
          ccs_log_error "settings.json 无法用 jq 解析(可能含注释), 请手动配置 statusLine"
          rm -f "$tmp"; return 1
        fi
      else
        printf '{\n  "statusLine": { "type": "command", "command": "%s" }\n}\n' "$cmd" > "$CCS_SETTINGS"
      fi
      ;;
    python3)
      python3 - "$CCS_SETTINGS" "$cmd" <<'PY'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        raw = f.read()
    data = json.loads(raw) if raw.strip() else {}
except FileNotFoundError:
    data = {}
except json.JSONDecodeError as e:
    print(f"[error] settings.json 无法解析({e}), 请手动配置 statusLine", file=sys.stderr)
    sys.exit(1)
data["statusLine"] = {"type": "command", "command": cmd}
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
      ;;
    none)
      ccs_log_error "需要 jq 或 python3 才能修改 settings.json"
      return 1
      ;;
  esac
}

# 从 settings.json 移除 statusLine(保留其余键)。返回 0 无论是否原本存在; 失败返回 1。
ccs_settings_remove_statusline() {
  if [ "$DRY_RUN" = 1 ]; then
    ccs_log_info "[dry-run] 将从 $CCS_SETTINGS 移除 statusLine"
    return 0
  fi
  [ -f "$CCS_SETTINGS" ] || return 0
  case "$(ccs_json_backend)" in
    jq)
      if jq -e 'has("statusLine")' "$CCS_SETTINGS" >/dev/null 2>&1; then
        local tmp; tmp="$(mktemp)"
        if jq 'del(.statusLine)' "$CCS_SETTINGS" > "$tmp"; then
          mv "$tmp" "$CCS_SETTINGS"
        else
          rm -f "$tmp"; ccs_log_error "settings.json 无法用 jq 解析"
          return 1
        fi
      fi
      ;;
    python3)
      python3 - "$CCS_SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(f"[error] settings.json 无法解析({e})", file=sys.stderr)
    sys.exit(1)
data.pop("statusLine", None)
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
      ;;
    none)
      ccs_log_error "需要 jq 或 python3 才能修改 settings.json"
      return 1
      ;;
  esac
}

# 检测 settings.json 是否含 statusLine。有返回 0, 无返回 1。
ccs_settings_has_statusline() {
  [ -f "$CCS_SETTINGS" ] || return 1
  case "$(ccs_json_backend)" in
    jq)     jq -e 'has("statusLine")' "$CCS_SETTINGS" >/dev/null 2>&1 ;;
    python3) python3 - "$CCS_SETTINGS" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    sys.exit(0 if "statusLine" in data else 1)
except Exception:
    sys.exit(1)
PY
      ;;
    *) return 1 ;;
  esac
}

# 输出 statusLine.command 的值(无则空字符串)。
ccs_settings_get_statusline_cmd() {
  [ -f "$CCS_SETTINGS" ] || return 0
  case "$(ccs_json_backend)" in
    jq)     jq -r '.statusLine.command // empty' "$CCS_SETTINGS" 2>/dev/null || true ;;
    python3) python3 - "$CCS_SETTINGS" <<'PY' || true
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get("statusLine", {}).get("command", ""))
except Exception:
    pass
PY
      ;;
  esac
}

# ---------- 执行原语 ----------
ccs_run() { # 支持 DRY_RUN=1 的通用执行器
  ccs_log_debug "run: $*"
  if [ "$DRY_RUN" = 1 ]; then
    ccs_log_info "[dry-run] $*"
    return 0
  fi
  "$@"
}

ccs_install_script() { # 用 mkdir+cp+chmod 部署脚本(比 install -D 更通用, 兼容 macOS)
  local src="$1" dst="$2"
  ccs_log_debug "deploy $src → $dst"
  ccs_run mkdir -p "$(dirname "$dst")"
  ccs_run cp "$src" "$dst"
  ccs_run chmod 0755 "$dst"
}

# 已装脚本与仓库源是否一致; 源不可比(缺失)视为 true, 已装缺失视为 false
ccs_installed_script_in_sync() {
  [ -f "$CCS_STATUSBAR_SOURCE" ] || return 0
  [ -f "$CCS_STATUSBAR_TARGET" ] || return 1
  cmp -s "$CCS_STATUSBAR_SOURCE" "$CCS_STATUSBAR_TARGET"
}

# ---------- 主流程(由各薄封装脚本调用) ----------
ccs_install_main() {
  ccs_log_info "1/3 部署状态栏脚本 → $CCS_STATUSBAR_TARGET"
  ccs_install_script "$CCS_STATUSBAR_SOURCE" "$CCS_STATUSBAR_TARGET"

  ccs_log_info "2/3 写入 statusLine 配置 → $CCS_SETTINGS (保留其他配置)"
  ccs_settings_set_statusline "bash $CCS_STATUSBAR_TARGET" || return 1

  ccs_log_info "3/3 注册 skill → $CCS_SKILL_LINK (软链接)"
  ccs_run mkdir -p "$(dirname "$CCS_SKILL_LINK")"
  ccs_run ln -sfn "$CCS_REPO_DIR" "$CCS_SKILL_LINK"

  printf '\n'
  ccs_log_info "安装完成。新开 Claude Code 会话即可看到状态栏:"
  echo "   <模型 ID> | <主机名>: <项目名> | [<服务名>:] <URL>"
  echo "  为项目声明服务 URL: 项目根目录创建 server-url.txt"
  echo "  格式(每行一个入口, 名称|URL, # 注释/空行忽略):"
  echo "    pc|http://IP:PORT"
  echo "  校验: bash scripts/verify.sh | 卸载: bash scripts/uninstall.sh"
}

ccs_uninstall_main() {
  ccs_log_info "1/3 从 settings.json 移除 statusLine"
  if ccs_settings_remove_statusline; then ccs_log_info "  ✔ 已移除 statusLine (其余配置保留)"; fi

  ccs_log_info "2/3 删除状态栏脚本"
  if [ -f "$CCS_STATUSBAR_TARGET" ]; then
    ccs_run rm -f "$CCS_STATUSBAR_TARGET"
    ccs_log_info "  ✔ 已删除 $CCS_STATUSBAR_TARGET"
  else
    ccs_log_debug "脚本不存在, 跳过"
  fi

  ccs_log_info "3/3 移除 skill 软链接(仅当指向本仓库)"
  if [ -L "$CCS_SKILL_LINK" ]; then
    if [ "$(readlink "$CCS_SKILL_LINK")" = "$CCS_REPO_DIR" ]; then
      ccs_run rm -f "$CCS_SKILL_LINK"
      ccs_log_info "  ✔ 已移除 $CCS_SKILL_LINK"
    else
      ccs_log_warn "  软链接指向其他位置, 未动"
    fi
  else
    ccs_log_debug "无软链接, 跳过"
  fi

  printf '\n'
  ccs_log_info "卸载完成。状态栏已恢复默认, 新会话生效。"
  ccs_log_info "提示: 项目根目录已有的 server-url.txt 不受影响, 可按需删除。"
}

ccs_verify_main() {
  local fail=0

  ccs_log_info "1/4 脚本存在与语法"
  if [ -f "$CCS_STATUSBAR_TARGET" ] && bash -n "$CCS_STATUSBAR_TARGET" 2>/dev/null; then
    ccs_log_info "  ✔ $CCS_STATUSBAR_TARGET 存在且语法正确"
  else
    ccs_log_error "  ✘ 脚本缺失或语法错误"
    fail=1
  fi

  ccs_log_info "2/4 settings.json 的 statusLine 配置"
  local want="bash $CCS_STATUSBAR_TARGET"
  local got; got="$(ccs_settings_get_statusline_cmd)"
  if [ -n "$got" ] && [ "$got" = "$want" ]; then
    ccs_log_info "  ✔ statusLine 已配置且 command 匹配"
  else
    ccs_log_error "  ✘ statusLine 未配置或不匹配 (期望: $want, 实际: ${got:-空})"
    fail=1
  fi

  ccs_log_info "3/4 已装脚本与仓库版本一致"
  if ccs_installed_script_in_sync; then
    ccs_log_info "  ✔ 已装脚本与仓库同步"
  else
    ccs_log_error "  ✘ 已装脚本与仓库不一致, 请重跑: bash scripts/install.sh"
    fail=1
  fi

  ccs_log_info "4/4 输出样例(带 server-url.txt)"
  local tmp out
  tmp="$(mktemp -d)"
  printf 'web|http://192.168.1.83:8080\n' > "$tmp/server-url.txt"
  out="$(CLAUDE_PROJECT_DIR="$tmp" bash "$CCS_STATUSBAR_TARGET" 2>/dev/null || true)"
  rm -rf "$tmp"
  ccs_log_info "  样例: $out"
  case "$out" in
    *"http://192.168.1.83:8080"*) ccs_log_info "  ✔ 样例输出包含声明的 URL" ;;
    *) ccs_log_error "  ✘ 样例输出缺少 URL"; fail=1 ;;
  esac

  printf '\n'
  if [ "$fail" = 0 ]; then ccs_log_info "校验通过"; return 0; fi
  ccs_log_error "校验失败, 请重新运行: bash scripts/install.sh"
  return 1
}

ccs_status_main() { # 安装状态总览: 只读, 不改动任何文件
  local ok=0 got want link_target
  ccs_log_info "claude-code-status v$CCS_VERSION — 安装状态"
  echo "  配置目录: $CLAUDE_DIR"

  echo "  状态栏脚本:"
  if [ -f "$CCS_STATUSBAR_TARGET" ]; then
    echo "    ✔ 已安装 ($CCS_STATUSBAR_TARGET)"
    if bash -n "$CCS_STATUSBAR_TARGET" 2>/dev/null; then
      echo "      语法: ✔"
    else
      echo "      语法: ✘"; ok=1
    fi
    if ccs_installed_script_in_sync; then
      echo "      与仓库同步: ✔"
    else
      echo "      与仓库同步: ⚠ 已过期 — 请重跑 bash scripts/install.sh"; ok=1
    fi
  else
    echo "    ✘ 未安装 — 请运行 bash scripts/install.sh"; ok=1
  fi

  echo "  settings.json:"
  if ccs_settings_has_statusline; then
    got="$(ccs_settings_get_statusline_cmd)"
    want="bash $CCS_STATUSBAR_TARGET"
    if [ -n "$got" ] && [ "$got" = "$want" ]; then
      echo "    ✔ statusLine 已配置且 command 匹配"
    else
      echo "    ⚠ statusLine 已配置但 command 不符 (实际: ${got:-空}, 期望: $want)"; ok=1
    fi
  else
    echo "    ✘ statusLine 未配置 — 请运行 bash scripts/install.sh"; ok=1
  fi

  echo "  skill 软链接:"
  if [ -L "$CCS_SKILL_LINK" ]; then
    link_target="$(readlink "$CCS_SKILL_LINK")"
    if [ "$link_target" = "$CCS_REPO_DIR" ]; then
      echo "    ✔ $CCS_SKILL_LINK → $CCS_REPO_DIR"
    else
      echo "    ⚠ 指向 $link_target (非本仓库)"; ok=1
    fi
  else
    echo "    ✘ 未注册 — 请运行 bash scripts/install.sh"; ok=1
  fi

  printf '\n'
  if [ "$ok" = 0 ]; then ccs_log_info "全部就绪"; return 0; fi
  ccs_log_warn "存在待处理项, 详见上方"
  return 1
}

# ---------- CLI ----------
CCS_USAGE_COMMON="通用选项: --help|-h 帮助; --version|-V 版本; --verbose|-v 详细输出; --dry-run 演练(不实际改动)"
CCS_USAGE_INSTALL="用法: bash scripts/install.sh [选项]

安装/更新 Claude Code 状态栏: 部署脚本到 \$CLAUDE_DIR、写入 settings.json 的 statusLine(保留其余配置)、注册 skill 软链接。
$CCS_USAGE_COMMON"
CCS_USAGE_UNINSTALL="用法: bash scripts/uninstall.sh [选项]

卸载 Claude Code 状态栏: 移除 statusLine 配置、状态栏脚本、skill 软链接(其余配置不受影响)。
$CCS_USAGE_COMMON"
CCS_USAGE_VERIFY="用法: bash scripts/verify.sh [选项]

校验状态栏安装: 脚本存在/语法、settings.json 的 statusLine、已装脚本与仓库同步、输出样例。全部通过返回 0。
$CCS_USAGE_COMMON"
CCS_USAGE_STATUS="用法: bash scripts/status.sh [选项]

查看 Claude Code 状态栏安装状态(只读): 脚本存在/语法/与仓库同步、settings.json 的 statusLine、skill 软链接。全部就绪返回 0。
$CCS_USAGE_COMMON"

ccs_cli_parse() { # 解析通用 CLI 选项; 第一参为 usage 文本
  local usage="$1"; shift
  for a in "$@"; do
    case "$a" in
      --help|-h) printf '%s\n' "$usage"; exit 0 ;;
      --version|-V) printf 'claude-code-status %s\n' "$CCS_VERSION"; exit 0 ;;
      --verbose|-v) VERBOSE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      *) ccs_log_warn "未知参数 '$a', 忽略 (用 --help 查看)" ;;
    esac
  done
}
