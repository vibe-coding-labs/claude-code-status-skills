#!/usr/bin/env bash
# statusbar-git-link.sh — Claude Code statusline 渲染脚本
# 输出: <主机名>: <项目名> (git 远程为超链接) | [<服务名>:] <URL> ...
# 依赖: CLAUDE_PROJECT_DIR(Claude Code 注入), bash(OSC8 超链接), git(可选)
# 自包含: 运行时被复制到 $CLAUDE_DIR, 不 source 外部库。
#
# 可配置环境变量(均有默认值, 覆盖后全局生效):
#   STATUSBAR_URL_FILE   server-url.txt 文件名   (默认 server-url.txt)
#   STATUSBAR_URL_SEP    名称与 URL 分隔符        (默认 |)
#   STATUSBAR_ENTRY_SEP  多个 URL 条目的间隔符    (默认 " | ")
#   STATUSBAR_COMMENT    注释行前缀              (默认 #)

set -euo pipefail

URL_FILE="${STATUSBAR_URL_FILE:-server-url.txt}"
URL_SEP="${STATUSBAR_URL_SEP:-|}"
ENTRY_SEP="${STATUSBAR_ENTRY_SEP:- | }"
COMMENT="${STATUSBAR_COMMENT:-#}"

# ---------- 工具函数 ----------

# 去除首尾空白
sb_trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# 将 URL 包成 OSC8 超链接, 显示文本=URL 本体
# (Terminator 用 BEL 结尾, 与 Claude Code 文档示例一致)
sb_oschlink() {
  printf '\e]8;;%s\a%s\e]8;;\a' "$1" "$1"
}

# 从 CLAUDE_PROJECT_DIR 解析项目目录; 无则尝试从 stdin(会话 JSON)解析
sb_project_dir() {
  local dir="${CLAUDE_PROJECT_DIR:-}"
  if [ -n "$dir" ]; then
    printf '%s' "$dir"; return 0
  fi
  # 无 stdin 可解析时仅显示主机名
  if [ -t 0 ]; then
    echo "(no project)"; return 1
  fi
  dir="$(sed -n 's/.*"project_dir":"\([^"]*\)".*/\1/p')"
  if [ -n "$dir" ]; then
    printf '%s' "$dir"
  else
    echo "(no project)"; return 1
  fi
}

# 解析 git remote.origin.url → 可点击的 https 链接(支持 worktree/submodule 的 .git 文件)
sb_git_repourl() {
  local project_dir="$1" remote
  git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1 || return 0
  remote="$(git -C "$project_dir" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$remote" ] || return 0
  if [[ "$remote" == git@* ]]; then            # git@host:owner/repo.git → https://host/owner/repo
    printf '%s' "$remote" | sed 's/:/\//g; s/git@/https:\/\//; s/\.git$//'
  elif [[ "$remote" == https://* ]]; then      # https://host/owner/repo.git → 去掉 .git
    printf '%s' "$remote" | sed 's/\.git$//'
  fi
}

# 读取 server-url.txt, 输出由 ENTRY_SEP 连接的 URL 条目(含 OSC8 超链接)
# 格式: 每行一个入口, 注释/空行忽略; 支持 名称|URL 标签(名称在链接外, URL 本体为超链接)
sb_server_urls() {
  local project_dir="$1" urlfile line name url link out=""
  urlfile="$project_dir/$URL_FILE"
  [ -f "$urlfile" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(sb_trim "$line")"
    [ -n "$line" ] || continue                            # 空行忽略
    case "$line" in "$COMMENT"*) continue ;; esac          # 注释忽略
    name=""
    url="$line"
    if [[ "$line" == *"$URL_SEP"* ]]; then                 # 名称|URL 标签格式
      name="${line%%"$URL_SEP"*}"
      url="${line#*"$URL_SEP"}"
      name="$(sb_trim "$name")"
    fi
    url="$(sb_trim "$url")"
    [ -n "$url" ] || continue
    link="$(sb_oschlink "$url")"
    if [ -n "$name" ]; then                                 # 名称前缀为普通文本, 不在链接内
      link="${name}: ${link}"
    fi
    out="${out}${out:+$ENTRY_SEP}${link}"
  done < "$urlfile" || true
  printf '%s' "$out"
}

# ---------- 主流程 ----------
project_dir="$(sb_project_dir)" || { echo "$(hostname -s): ${project_dir:-}"; exit 0; }
base="$(basename "$project_dir")"
host="$(hostname -s)"
repourl="$(sb_git_repourl "$project_dir")"
extra="$(sb_server_urls "$project_dir")"

if [ -n "$repourl" ]; then
  # 仅项目名为超链接(OSC8)
  printf '%s: \e]8;;%s\a%s\e]8;;\a%s\n' "$host" "$repourl" "$base" "${extra:+ | $extra}"
else
  echo "${host}: ${base}${extra:+ | $extra}"
fi
