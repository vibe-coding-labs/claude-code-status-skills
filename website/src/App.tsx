import { useEffect, useState } from 'react'
import { copy, readmeUrl, repoUrl, type Copy, type Lang } from './content'
import './index.css'

const storedLang = (): Lang => {
  const fromUrl = new URLSearchParams(window.location.search).get('lang')
  if (fromUrl === 'zh' || fromUrl === 'en') return fromUrl
  const saved = localStorage.getItem('lang')
  return saved === 'zh' || saved === 'en' ? saved : 'en'
}

function Sep() {
  return <span className="sep"> | </span>
}

function StatusLine({ c }: { c: Copy }) {
  const { status } = c
  return (
    <div className="bar" role="img" aria-label={c.shows.heading}>
      <span className="caret" aria-hidden="true">❯</span>
      <p className="row">
        <span className="seg model">{status.model}</span>
        <span className="seg"><Sep />{status.host}</span>
        <span className="seg"><Sep /><a className="osc" href={repoUrl}>{status.project}</a></span>
        {status.entries.map((entry) => (
          <span className="seg" key={entry.name}>
            <Sep />
            <span className="name">{entry.name}: </span>
            <a className="osc" href={entry.url}>{entry.url}</a>
          </span>
        ))}
      </p>
    </div>
  )
}

function Code({ lines }: { lines: string[] }) {
  const [copied, setCopied] = useState(false)
  const text = lines.join('\n')

  const onCopy = () => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    })
  }

  return (
    <div className="code">
      <button type="button" onClick={onCopy} aria-live="polite">
        {copied ? '✓' : 'copy'}
      </button>
      <pre>
        <code>{text}</code>
      </pre>
    </div>
  )
}

export default function App() {
  const [lang, setLang] = useState<Lang>(storedLang)
  const [tab, setTab] = useState<'marketplace' | 'script'>('marketplace')
  const c = copy[lang]

  useEffect(() => {
    document.documentElement.lang = c.htmlLang
    document.title = c.title
    localStorage.setItem('lang', lang)
  }, [lang, c])

  const install = tab === 'marketplace' ? c.install.marketplace : c.install.script

  return (
    <>
      <header className="top">
        <a className="brand" href="#top">claude-code-status</a>
        <nav>
          <a href={readmeUrl}>{c.nav.readme}</a>
          <a href={repoUrl}>{c.nav.github}</a>
          <button
            type="button"
            className="lang"
            onClick={() => setLang(lang === 'en' ? 'zh' : 'en')}
          >
            {c.nav.lang}
          </button>
        </nav>
      </header>

      <main id="top">
        <section className="hero">
          <p className="kicker">{c.hero.kicker}</p>
          <StatusLine c={c} />
          <p className="lead">{c.hero.lead}</p>
          <p className="actions">
            <a className="primary" href="#install">{c.hero.install}</a>
            <a href={readmeUrl}>{c.hero.readme}</a>
          </p>
        </section>

        <section className="anatomy">
          <ul>
            {c.status.hints.map((hint) => (
              <li key={hint.label}>
                <code>{hint.label}</code>
                <span>{hint.text}</span>
              </li>
            ))}
          </ul>
        </section>

        <section id="install">
          <h2>{c.install.heading}</h2>
          <div className="tabs" role="tablist">
            {c.install.tabs.map((item) => (
              <button
                key={item.id}
                type="button"
                role="tab"
                aria-selected={tab === item.id}
                className={tab === item.id ? 'on' : ''}
                onClick={() => setTab(item.id)}
              >
                {item.label}
              </button>
            ))}
          </div>
          <p className="note">{install.note}</p>
          <Code lines={install.lines} />
        </section>

        <section>
          <h2>{c.shows.heading}</h2>
          <dl className="shows">
            {c.shows.items.map((item) => (
              <div key={item.term}>
                <dt>{item.term}</dt>
                <dd>{item.text}</dd>
              </div>
            ))}
          </dl>
        </section>

        <section>
          <h2>{c.how.heading}</h2>
          <ol className="how">
            {c.how.steps.map((step, i) => (
              <li key={step.title}>
                <span className="n">{i + 1}</span>
                <div>
                  <h3>{step.title}</h3>
                  <p>{step.text}</p>
                </div>
              </li>
            ))}
          </ol>
        </section>
      </main>

      <footer>
        <p>{c.footer}</p>
        <p><a href={repoUrl}>vibe-coding-labs/claude-code-status-skills</a></p>
      </footer>
    </>
  )
}
