# Claude Code 状态栏 Skill

一个可安装、可配置的 [Claude Code](https://claude.com/claude-code) 状态栏（statusline）封装。状态栏展示 **主机名 / 项目 git 链接 / 局域网服务 URL**，通过一个 skill 完成安装、配置、校验与卸载。

## 效果

```
local-server-002: PaiMian | backend: http://192.168.1.83:30816 | pc: http://192.168.1.83:8080
```

- `PaiMian` → 可点击的 git 仓库链接（自动解析 `git remote`）
- `backend: http://…` → 可点击的局域网服务 URL（由 `server-url.txt` 声明）

## 快速开始

```bash
# 1. 克隆仓库
git clone <this-repo> && cd claude-code-status-skills

# 2. 安装（部署脚本 + 配置 settings.json + 注册 skill）
bash scripts/install.sh

# 3. 校验
bash scripts/verify.sh

# 4. 新开 Claude Code 会话 → 状态栏生效
```

为项目声明服务 URL：在项目根目录创建 `server-url.txt`：

```text
backend|http://192.168.1.83:30816
pc|http://192.168.1.83:8080
```

之后状态栏即显示 `backend: http://192.168.1.83:30816`（可点击）。

## 目录结构

```
claude-code-status-skills/
├── SKILL.md                    # skill 入口（Claude 按此执行安装/配置/校验/卸载）
├── scripts/
│   ├── install.sh              # 安装：部署脚本 + 合并 settings.json + 注册 skill
│   ├── uninstall.sh            # 卸载：移除配置/脚本/skill 链接
│   ├── verify.sh               # 校验：脚本语法 + 配置 + 输出样例
│   └── statusbar-git-link.sh   # 状态栏脚本本体（OSC8 超链接渲染）
└── tests/
    └── test_statusbar.sh       # 隔离冒烟测试（临时 CLAUDE_DIR，不碰真实配置）
```

## 使用方式

| 场景 | 命令 |
|------|------|
| 安装 / 更新 | `bash scripts/install.sh` |
| 校验 | `bash scripts/verify.sh` |
| 卸载 | `bash scripts/uninstall.sh` |
| 为项目配置 URL | 项目根目录建 `server-url.txt`（或 `/server-url` skill） |

所有脚本支持 `CLAUDE_DIR` 环境变量覆盖（默认 `~/.claude`），便于测试隔离。

## 原理

- `settings.json` 的 `statusLine` 指向 `statusbar-git-link.sh`，脚本用 `CLAUDE_PROJECT_DIR` 定位项目根目录，读取 `server-url.txt` 并以 OSC 8 超链接渲染。
- skill 本体通过软链接注册到 `~/.claude/skills/`，仓库更新即生效。

## License

MIT
