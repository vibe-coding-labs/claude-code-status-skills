export type Lang = 'en' | 'zh'

export interface Copy {
  htmlLang: string
  title: string
  nav: { readme: string; github: string; lang: string }
  hero: {
    kicker: string
    lead: string
    install: string
    readme: string
  }
  status: {
    model: string
    host: string
    project: string
    entries: { name: string; url: string }[]
    hints: { label: string; text: string }[]
  }
  install: {
    heading: string
    tabs: { id: 'marketplace' | 'script'; label: string }[]
    marketplace: { note: string; lines: string[] }
    script: { note: string; lines: string[] }
  }
  shows: { heading: string; items: { term: string; text: string }[] }
  how: { heading: string; steps: { title: string; text: string }[] }
  footer: string
}

export const repoUrl = 'https://github.com/vibe-coding-labs/claude-code-status-skills'
export const readmeUrl = `${repoUrl}#readme`

const status = {
  model: 'claude-opus-5',
  host: 'local-server-002',
  project: 'PaiMian',
  entries: [
    { name: 'backend', url: 'http://192.168.1.83:30816' },
    { name: 'pc', url: 'http://192.168.1.83:8080' },
  ],
}

export const copy: Record<Lang, Copy> = {
  en: {
    htmlLang: 'en',
    title: 'claude-code-status — a status line for Claude Code',
    nav: { readme: 'README', github: 'GitHub', lang: '中文' },
    hero: {
      kicker: 'a status line for Claude Code',
      lead: 'The model you are on, the machine you are on, a clickable link to the repo, and the services running inside it — one quiet row at the bottom of the session.',
      install: 'Install',
      readme: 'Read the README',
    },
    status: {
      ...status,
      hints: [
        { label: 'claude-opus-5', text: 'the model this session is using, read from model.id. Omitted when unknown.' },
        { label: 'local-server-002', text: 'the hostname, so you can tell sessions on different machines apart.' },
        { label: 'PaiMian', text: 'the project, linked to its git remote. SSH and HTTPS remotes both work.' },
        { label: 'pc: http://…', text: 'LAN services declared in server-url.txt. Only the URL is the link.' },
      ],
    },
    install: {
      heading: 'Install',
      tabs: [
        { id: 'marketplace', label: 'Marketplace' },
        { id: 'script', label: 'Install script' },
      ],
      marketplace: {
        note: 'Inside a Claude Code session. The skill registers immediately; open a new session and the status line is there.',
        lines: [
          '/plugin marketplace add vibe-coding-labs/claude-code-status-skills',
          '/plugin install claude-code-status@claude-code-status-skills',
        ],
      },
      script: {
        note: 'Deploys the script, merges settings.json without touching your other keys, and symlinks the skill.',
        lines: [
          'git clone https://github.com/vibe-coding-labs/claude-code-status-skills.git',
          'cd claude-code-status-skills',
          'bash scripts/install.sh',
        ],
      },
    },
    shows: {
      heading: 'What the row shows',
      items: [
        { term: 'model id', text: 'The exact model the session is running, taken from the JSON Claude Code passes the status line on stdin. No JSON, no segment.' },
        { term: 'hostname', text: 'Which machine this session lives on. Useful when several machines share one screen.' },
        { term: 'repository', text: 'The project name, parsed from git remote and wrapped in an OSC 8 hyperlink your terminal can open.' },
        { term: 'services', text: 'One entry per line of server-url.txt. List the pages you actually open — frontends, admin consoles, doc sites — and skip bare API roots.' },
      ],
    },
    how: {
      heading: 'How it works',
      steps: [
        { title: 'settings.json points at a script', text: 'install.sh writes a statusLine command and leaves every other key alone. Uninstall removes only that.' },
        { title: 'the script reads the session', text: 'Claude Code feeds it JSON on stdin. model.id comes from there; the project root comes from CLAUDE_PROJECT_DIR.' },
        { title: 'server-url.txt is the contract', text: 'A plain text file in the project root, one entry per line, name|url or a bare url. Comments and blank lines are ignored.' },
      ],
    },
    footer: 'MIT licensed. The status line script is self-contained — once installed it does not depend on this repo.',
  },
  zh: {
    htmlLang: 'zh-CN',
    title: 'claude-code-status — Claude Code 的状态栏',
    nav: { readme: 'README', github: 'GitHub', lang: 'English' },
    hero: {
      kicker: 'Claude Code 的状态栏',
      lead: '当前用的哪个模型、会话在哪台机器上、仓库的可点击链接、项目里跑着哪些服务——会话底部安静的一行。',
      install: '安装',
      readme: '阅读 README',
    },
    status: {
      ...status,
      hints: [
        { label: 'claude-opus-5', text: '当前会话正在使用的模型，取自 model.id；取不到时这一段省略。' },
        { label: 'local-server-002', text: '主机名，用来区分不同机器上的会话。' },
        { label: 'PaiMian', text: '项目名，链接到 git 远程。SSH 和 HTTPS 都支持。' },
        { label: 'pc: http://…', text: 'server-url.txt 里声明的局域网服务，只有 URL 本身是链接。' },
      ],
    },
    install: {
      heading: '安装',
      tabs: [
        { id: 'marketplace', label: 'Marketplace' },
        { id: 'script', label: '安装脚本' },
      ],
      marketplace: {
        note: '在 Claude Code 会话里执行。skill 立即注册；新开一个会话，状态栏就在了。',
        lines: [
          '/plugin marketplace add vibe-coding-labs/claude-code-status-skills',
          '/plugin install claude-code-status@claude-code-status-skills',
        ],
      },
      script: {
        note: '部署脚本、合并 settings.json 且不动其他配置、把 skill 软链接注册到位。',
        lines: [
          'git clone https://github.com/vibe-coding-labs/claude-code-status-skills.git',
          'cd claude-code-status-skills',
          'bash scripts/install.sh',
        ],
      },
    },
    shows: {
      heading: '这一行里有什么',
      items: [
        { term: '模型 ID', text: '会话正在跑的模型全称，取自 Claude Code 经 stdin 传给状态栏的 JSON。没有 JSON 就没有这一段。' },
        { term: '主机名', text: '这个会话在哪台机器上。多台机器共用一块屏幕时一眼能分清。' },
        { term: '仓库', text: '项目名，从 git remote 解析，包成终端可以直接打开的 OSC 8 超链接。' },
        { term: '服务', text: 'server-url.txt 每行一个入口。只收录你真的会点开的页面——前端、管理后台、文档站，纯 API 根路径不用放。' },
      ],
    },
    how: {
      heading: '它是怎么工作的',
      steps: [
        { title: 'settings.json 指向一个脚本', text: 'install.sh 写入 statusLine 命令，其余键原样保留。卸载只删这一项。' },
        { title: '脚本读取会话', text: 'Claude Code 把 JSON 从 stdin 传进来。model.id 取自这里，项目根目录取自 CLAUDE_PROJECT_DIR。' },
        { title: 'server-url.txt 是约定', text: '项目根目录的纯文本文件，每行一个入口，名称|URL 或裸 URL。注释和空行会被忽略。' },
      ],
    },
    footer: 'MIT 许可。状态栏脚本是自包含的——装好之后不再依赖这个仓库。',
  },
}
