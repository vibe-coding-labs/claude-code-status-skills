# Claude Code Status Line

[English](README.md) | [简体中文](README.zh-CN.md)

An installable, configurable [Claude Code](https://claude.com/claude-code) status line, packaged as a skill. It shows the **current model ID**, the **hostname**, a **clickable git repository link**, and **clickable LAN service URLs**, and one skill handles install, configuration, verification, and uninstall.

Website: <https://vibe-coding-labs.github.io/claude-code-status-skills/>

## What it looks like

```
claude-opus-5 | local-server-002 | PaiMian | backend: http://192.168.1.83:30816 | pc: http://192.168.1.83:8080
```

- `claude-opus-5` — the model ID the current session is using, read from `model.id` in the session JSON Claude Code passes to the status line command. The segment is omitted when it cannot be determined.
- `PaiMian` — a clickable link to the git repository (parsed from `git remote`, SSH and HTTPS both supported).
- `backend: http://…` — a clickable LAN service URL declared in `server-url.txt`. Only the URL itself is the hyperlink; the name prefix is plain text.

## Install

### Option 1: Claude Code marketplace (recommended)

Inside a Claude Code session:

```text
/plugin marketplace add vibe-coding-labs/claude-code-status-skills
/plugin install claude-code-status@claude-code-status-skills
```

Or from a terminal:

```bash
claude plugin marketplace add vibe-coding-labs/claude-code-status-skills
claude plugin install claude-code-status@claude-code-status-skills
```

This registers the skill. The status line itself is activated by the install script (next section), which the skill runs for you — open a new session afterwards and ask Claude to install the status line, or run the script directly.

### Option 2: install script

```bash
git clone https://github.com/vibe-coding-labs/claude-code-status-skills.git
cd claude-code-status-skills
bash scripts/install.sh    # deploy the script, merge settings.json, register the skill
bash scripts/verify.sh     # check the result
```

Open a new Claude Code session and the status line takes effect.

### Declare service URLs for a project

Create `server-url.txt` in the project root (or let the `/server-url` skill generate it). Status line URLs exist to make jumping convenient, so list only **homepage-style** entries — frontend pages, admin consoles, doc sites. A bare backend API base URL is usually not worth listing:

```text
pc|http://192.168.1.83:8080
admin|http://192.168.1.83:8080/admin
```

The status line then shows `pc: http://192.168.1.83:8080` (clickable). If the project is a git repository, add `server-url.txt` to `.gitignore` so internal addresses are not committed.

## Usage

| Task | Command |
|------|---------|
| Install / update | `bash scripts/install.sh` |
| Verify (includes a sync check against the repo) | `bash scripts/verify.sh` |
| Show install status (read-only) | `bash scripts/status.sh` |
| Uninstall | `bash scripts/uninstall.sh` |
| Preview without changing anything | append `--dry-run` to the commands above |
| Declare URLs for a project | create `server-url.txt` in the project root |

### `server-url.txt` format

One entry per line. Lines starting with `#` and blank lines are ignored, and a URL must not contain `|`:

```text
# service entries (updated 2026-08-17)
pc|http://192.168.1.83:8080
admin|http://192.168.1.83:8080/admin
doc|http://192.168.1.83:8081/swagger-ui.html
```

- `name|http://IP:PORT` — named entry (recommended); shown as `name: URL`.
- `http://IP:PORT` — unnamed; the URL is shown on its own.

What belongs in the file:

| Kind | Examples | Include? |
|------|----------|----------|
| Frontend page / admin console | Vite/Webpack/Next dev server, admin backend, nginx entry | Yes |
| API docs / visual playground | Swagger UI, `/doc.html`, GraphQL Playground | Yes (the docs path, not the bare API root) |
| Bare backend API base URL | `/api` root of Spring Boot / Express / FastAPI | No by default |
| Health checks / metrics / WebSocket / gRPC | `/actuator`, `/health`, protocol-only ports | No |

One project usually needs one to three entries. A quick check: `curl -s -o /dev/null -w '%{content_type}\n' http://IP:PORT/` — `text/html` is usually a page (include it), `application/json` or a failed connection is usually an API (leave it out).

### CLI options

| Option | Meaning |
|--------|---------|
| `--help` / `-h` | Show usage |
| `--version` / `-V` | Show the version |
| `--verbose` / `-v` | Debug logging |
| `--dry-run` | Print what would happen without changing anything |

### Environment variables

| Variable | Meaning | Default |
|----------|---------|---------|
| `CLAUDE_DIR` | Claude Code config root (handy for isolated tests) | `~/.claude` |
| `STATUSBAR_URL_FILE` | File name read instead of `server-url.txt` | `server-url.txt` |
| `STATUSBAR_URL_SEP` | Separator between a name and its URL | `\|` |
| `STATUSBAR_ENTRY_SEP` | Separator between URL entries | ` \| ` |
| `STATUSBAR_COMMENT` | Prefix marking a comment line | `#` |
| `CCS_JSON_BACKEND` | Force the JSON backend: `jq` or `python3` (empty = auto) | auto |

The `STATUSBAR_*` variables control rendering and can be injected in front of the status line command:

```bash
STATUSBAR_URL_FILE=urls.txt STATUSBAR_ENTRY_SEP="  " bash ~/.claude/statusbar-git-link.sh
```

## Layout

```
claude-code-status-skills/
├── .github/workflows/pages.yml # 构建 website/ 并部署到 GitHub Pages
├── website/                    # 官网（TypeScript + React，中英切换）
├── .claude-plugin/
│   ├── marketplace.json        # marketplace manifest (enables /plugin marketplace add)
│   └── plugin.json             # plugin manifest
├── SKILL.md                    # skill entry (Claude follows it to install/configure/verify/uninstall)
├── scripts/
│   ├── lib.sh                  # shared library: config, logging, JSON backend, settings, CLI parsing
│   ├── install.sh              # install: deploy script + merge settings.json + register skill
│   ├── uninstall.sh            # uninstall: remove config, script, and skill symlink
│   ├── verify.sh               # verify: syntax, config, sync check, sample output
│   ├── status.sh               # status: read-only overview (script/config/symlink/sync)
│   └── statusbar-git-link.sh   # the status line script (OSC 8 hyperlinks, self-contained)
└── tests/
    └── test_statusbar.sh       # isolated smoke test (12 sections, temp CLAUDE_DIR, never touches real config)
```

## Design notes

- **Modular**: the management scripts are thin wrappers (~10 lines each) over `scripts/lib.sh`, so no logic is duplicated.
- **Two JSON backends**: `settings.json` is read and written with `jq`, falling back to `python3` when `jq` is missing; both missing is an error. `CCS_JSON_BACKEND` forces one.
- **Safe to install**: every write goes through `ccs_run`, so `--dry-run` previews it. Merging `settings.json` keeps every other key, and uninstall removes only `statusLine`.
- **Drift is visible**: `verify.sh` and `status.sh` compare the installed script with the repo copy (`cmp`) and tell you to re-run install when they differ. `status.sh` is read-only.
- **Self-contained status line script**: at runtime it is copied to `~/.claude/` and depends on nothing in the repo, while staying configurable through the `STATUSBAR_*` variables.
- **Robust input handling**: `server-url.txt` accepts bare URLs and `name|URL` lines, `#` comments, blank lines, surrounding whitespace, and a final line without a newline. Reading the session JSON from stdin is time-bounded, so a status line pipe that is written but never closed cannot hang the refresh. Commands are written to behave under `set -euo pipefail`.

## How it works

- `settings.json`'s `statusLine` points at `statusbar-git-link.sh`. The script locates the project root from `CLAUDE_PROJECT_DIR` (falling back to `workspace.project_dir` in the stdin JSON), reads `server-url.txt`, and renders links as OSC 8 hyperlinks.
- The current model ID comes from `model.id` in the session JSON Claude Code feeds the command on stdin. Parsing prefers `jq`, then `python3`, then a `sed` fallback.
- The skill itself is registered as a symlink under `~/.claude/skills/`, so updating the repo updates the skill.

## License

MIT
