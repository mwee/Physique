/* PHYSIQUE — UI primitives, icons, charts (exports to window) */

const ICONS = {
  home: 'M3 11l9-7 9 7v8a2 2 0 0 1-2 2h-3v-6H8v6H5a2 2 0 0 1-2-2v-8z',
  calendar: 'M3 9h18M8 2v4M16 2v4 M5 4h14a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z',
  progress: 'M4 19V5M4 15l5-5 4 3 7-8',
  dumbbell: 'M6.5 6.5l11 11M4 9l-1.5-1.5M9 4 7.5 2.5M20 15l1.5 1.5M15 20l1.5 1.5M5 12l7-7 7 7-7 7-7-7z',
  timer: 'M12 14V9M9 2h6 M12 22a8 8 0 1 0 0-16 8 8 0 0 0 0 16z',
  plus: 'M12 5v14M5 12h14',
  check: 'M4 12l5 5L20 6',
  chevR: 'M9 5l7 7-7 7',
  chevL: 'M15 5l-7 7 7 7',
  ellipsis: 'M5 12h.01M12 12h.01M19 12h.01',
  link: 'M9 15l6-6M10.5 6.5l1.8-1.8a3.5 3.5 0 0 1 5 5L15.5 11M8.5 13l-1.8 1.8a3.5 3.5 0 0 0 5 5L13.5 18',
  flame: 'M12 2c1 3 5 4.5 5 9a5 5 0 0 1-10 0c0-1.5.5-2.5 1-3 .2 1.2 1 2 2 2 0-2.5-1-4 2-8z',
  search: 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-3.5-3.5',
  x: 'M5 5l14 14M19 5L5 19',
  settings: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 13a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.2A1.6 1.6 0 0 0 7 19.3a1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H1a2 2 0 1 1 0-4h.2A1.6 1.6 0 0 0 2.7 7a1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 8 2.6V2a2 2 0 1 1 4 0v.2A1.6 1.6 0 0 0 14.7 4a1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H21a2 2 0 1 1 0 4h-.2a1.6 1.6 0 0 0-1.4 1z',
  lock: 'M5 11h14v10H5V11zM8 11V7a4 4 0 0 1 8 0v4',
  bolt: 'M13 2L4 14h7l-1 8 9-12h-7l1-8z',
  play: 'M6 4l14 8-14 8V4z',
  edit: 'M4 20h4L18 9l-4-4L4 16v4zM14 5l4 4',
  clock: 'M12 7v5l3 2M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
  arrowUp: 'M12 19V5M5 12l7-7 7 7',
  arrowR: 'M5 12h14M13 6l6 6-6 6',
  chart: 'M4 19V5M4 19h16M8 16v-4M12 16V9M16 16v-7',
  list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01',
  flag: 'M4 21V4M4 4h13l-2 4 2 4H4',
  spark: 'M12 3l1.7 4.6 4.6 1.7-4.6 1.7L12 15.6l-1.7-4.6L5.7 9.3l4.6-1.7L12 3z M18.5 13.5l.8 2.1 2.1.8-2.1.8-.8 2.1-.8-2.1-2.1-.8 2.1-.8.8-2.1z',
  info: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z M12 11v5 M12 7.6h.01',
  chevD: 'M5 9l7 7 7-7',
  send: 'M4 12l16-8-6 16-3-6-7-2z',
  clipboard: 'M9 4.5h6a1 1 0 0 1 1 1V7H8V5.5a1 1 0 0 1 1-1z M8 6H6a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-2 M8.5 12h7 M8.5 16h5',
};

function Icon({ name, size = 22, color = 'currentColor', sw = 1.9, fill = false, style }) {
  const path = ICONS[name] || '';
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" style={style}>
      {path.split(' M').map((seg, i) => (
        <path key={i} d={(i ? 'M' : '') + seg}
          stroke={fill ? 'none' : color} strokeWidth={sw}
          fill={fill ? color : 'none'}
          strokeLinecap="round" strokeLinejoin="round" />
      ))}
    </svg>
  );
}

function Btn({ children, variant = 'primary', onClick, style = {}, full = true, size = 'md' }) {
  const base = {
    fontFamily: 'var(--font)', fontWeight: 600, border: 0, cursor: 'pointer',
    borderRadius: 'var(--r-sm)', display: 'inline-flex', alignItems: 'center',
    justifyContent: 'center', gap: 8, width: full ? '100%' : 'auto',
    transition: 'filter .15s ease, transform .08s ease',
    fontSize: size === 'sm' ? 14 : 16,
    padding: size === 'sm' ? '9px 14px' : '14px 20px',
    WebkitTapHighlightColor: 'transparent',
  };
  const variants = {
    primary: { background: 'var(--accent)', color: 'var(--on-accent)' },
    secondary: { background: 'var(--accent-soft)', color: 'var(--accent)' },
    ghost: { background: 'var(--surface-2)', color: 'var(--text)' },
    destructive: { background: 'var(--danger-soft)', color: 'var(--danger)' },
    success: { background: 'var(--success)', color: '#fff' },
  };
  return (
    <button style={{ ...base, ...variants[variant], ...style }}
      onMouseDown={e => e.currentTarget.style.transform = 'scale(0.985)'}
      onMouseUp={e => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
      onClick={onClick}>{children}</button>
  );
}

function Card({ children, style = {}, onClick, pad = 'var(--s5)' }) {
  return (
    <div onClick={onClick} style={{
      background: 'var(--surface)', borderRadius: 'var(--r-lg)', padding: pad,
      border: '1px solid var(--hairline)', boxShadow: 'var(--shadow)',
      cursor: onClick ? 'pointer' : 'default', ...style,
    }}>{children}</div>
  );
}

function SetTypeBadge({ type }) {
  const isW = type === 'W';
  return (
    <span style={{
      fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums',
      fontWeight: 700, fontSize: 15,
      color: isW ? 'var(--warmup)' : 'var(--text)',
    }}>{type}</span>
  );
}

function Pill({ children, tone = 'neutral', style = {} }) {
  const tones = {
    neutral: { background: 'var(--surface-2)', color: 'var(--text-2)' },
    accent: { background: 'var(--accent-soft)', color: 'var(--accent)' },
    pr: { background: 'var(--pr-soft)', color: 'var(--pr)' },
    success: { background: 'color-mix(in srgb, var(--success) 16%, transparent)', color: 'var(--success)' },
  };
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontSize: 12, fontWeight: 700, padding: '4px 9px', borderRadius: 'var(--r-xs)',
      fontVariantNumeric: 'tabular-nums', ...tones[tone], ...style,
    }}>{children}</span>
  );
}

// ---------- Charts ----------
function LineChart({ data, height = 96, w = 320, stroke = 'var(--accent)', area = true, dot = true }) {
  const pad = 6;
  const max = Math.max(...data), min = Math.min(...data);
  const rng = max - min || 1;
  const xs = i => pad + i * (w - 2 * pad) / (data.length - 1);
  const ys = v => height - pad - (v - min) / rng * (height - 2 * pad);
  let dline = '';
  data.forEach((v, i) => { dline += (i ? 'L' : 'M') + xs(i).toFixed(1) + ' ' + ys(v).toFixed(1) + ' '; });
  const gid = 'lg' + Math.random().toString(36).slice(2, 7);
  return (
    <svg viewBox={`0 0 ${w} ${height}`} style={{ width: '100%', height, display: 'block' }} preserveAspectRatio="none">
      {area && (<>
        <defs><linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={stroke} stopOpacity="0.26" />
          <stop offset="1" stopColor={stroke} stopOpacity="0" />
        </linearGradient></defs>
        <path d={`${dline}L ${xs(data.length - 1)} ${height} L ${xs(0)} ${height} Z`} fill={`url(#${gid})`} />
      </>)}
      <path d={dline} fill="none" stroke={stroke} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      {dot && <circle cx={xs(data.length - 1)} cy={ys(data[data.length - 1])} r="3.6" fill={stroke} />}
    </svg>
  );
}

function BarChart({ data, height = 96, w = 320, highlightLast = true }) {
  const pad = 4, gap = 7;
  const bw = (w - 2 * pad - gap * (data.length - 1)) / data.length;
  const max = Math.max(...data) || 1;
  return (
    <svg viewBox={`0 0 ${w} ${height}`} style={{ width: '100%', height, display: 'block' }} preserveAspectRatio="none">
      {data.map((v, i) => {
        const bh = Math.max(3, (v / max) * (height - 8));
        const x = pad + i * (bw + gap), y = height - bh;
        const last = highlightLast && i === data.length - 1;
        return <rect key={i} x={x} y={y} width={bw} height={bh} rx="3"
          fill={last ? 'var(--accent)' : 'var(--surface-3)'} />;
      })}
    </svg>
  );
}

Object.assign(window, { Icon, Btn, Card, SetTypeBadge, Pill, LineChart, BarChart });
