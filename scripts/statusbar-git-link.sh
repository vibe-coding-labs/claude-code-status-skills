#!/usr/bin/env bash
# statusbar-git-link.sh
# Extracts the project name from CLAUDE_PROJECT_DIR, resolves the Git
# remote URL to an HTTP link, and renders it as an iTerm2 OSC 8 hyperlink.

set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$project_dir" ]; then
  # Fallback: try to parse from the session transcript JSON (if passed via stdin)
  if [ -t 0 ]; then
    # No stdin available — just show hostname
    echo "$(hostname -s): (no project)"
    exit 0
  fi
  project_dir=$(sed -n 's/.*"project_dir":"\([^"]*\)".*/\1/p')
fi

base=$(basename "$project_dir")
host=$(hostname -s)

# Try to resolve a GitHub/Bitbucket/GitLab remote URL
repourl=""
# Detect git via git itself: works for normal repos AND worktrees/submodules
# where .git is a plain file, not a directory (the old [ -d .git ] check
# silently produced no link in worktree sessions).
if git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
  remote=$(git -C "$project_dir" config --get remote.origin.url 2>/dev/null || true)

  if [ -n "$remote" ]; then
    # Convert SSH-style git@github.com:owner/repo.git → https://github.com/owner/repo
    if [[ "$remote" == git@* ]]; then
      repourl=$(echo "$remote" | sed 's/:/\//g; s/git@/https:\/\//; s/\.git$//')
    # Convert standard https://github.com/owner/repo.git → strip .git
    elif [[ "$remote" == https://* ]]; then
      repourl=$(echo "$remote" | sed 's/\.git$//')
    fi
  fi
fi

# 读取约定的局域网 URL 文件（server-url.txt）
# 格式：每行一个入口，# 开头为注释、空行忽略；
#       可选 名称|URL 标签（URL 不得含 |），无名称则整行即 URL；
#       名称显示为普通文本，URL 本体为 OSC8 超链接，多个用 " | " 分隔
urlfile="$project_dir/server-url.txt"
extra=""
if [ -f "$urlfile" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$line" ] || continue                      # 空行忽略
    case "$line" in \#*) continue ;; esac           # # 注释忽略
    name=""
    url="$line"
    if [[ "$line" == *"|"* ]]; then                 # 名称|URL 标签格式
      name="${line%%|*}"
      url="${line#*|}"
      name="$(printf '%s' "$name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    fi
    url="$(printf '%s' "$url" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$url" ] || continue
    # 超链接只包裹 URL 本体；名称前缀作为普通文本(不在链接内)
    link=$(printf '\e]8;;%s\a%s\e]8;;\a' "$url" "$url")
    if [ -n "$name" ]; then
      link="${name}: ${link}"
    fi
    extra="${extra}${extra:+ | }${link}"
  done < "$urlfile" || true
fi

if [ -n "$repourl" ]; then
  # OSC 8 hyperlink — only the project name is clickable.
  # Terminator uses BEL (\a) to match Claude Code's documented statusline example.
  printf '%s: \e]8;;%s\a%s\e]8;;\a%s\n' "$host" "$repourl" "$base" "${extra:+ | $extra}"
else
  echo "${host}: ${base}${extra:+ | $extra}"
fi
