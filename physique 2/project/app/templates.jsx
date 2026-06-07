/* PHYSIQUE — Template Library exploration
   Browse built-in spreadsheet programs (5/3/1, GZCLP, Texas Method, Madcow,
   Smolov Jr), enter & live-tweak your 1RM, watch the plan recompute, then save
   the configured template to your library. Self-contained: reuses ui.jsx
   primitives, the iOS frame, the tweaks panel and design tokens. */

const { useState, useEffect, useRef } = React;
const SAFE_TOP = 56;
const KG2LB = 2.20462;

/* ---------- math ---------- */
const incFor = (u) => (u === 'lb' ? 5 : 2.5);
const roundTo = (x, s) => Math.round(x / s) * s;
const fmtW = (x) => (Number.isInteger(x) ? String(x) : (Math.round(x * 10) / 10).toFixed(1).replace(/\.0$/, ''));
function basisWeight(oneRM, prog, tmPct, unit) {
  if (prog.basis === 'tm') return roundTo(oneRM * (tmPct / 100), incFor(unit));
  return oneRM;
}
function setWeight(oneRM, p, prog, tmPct, unit) {
  return roundTo(basisWeight(oneRM, prog, tmPct, unit) * p, incFor(unit));
}
function convertMaxes(maxes, to) {
  const out = {};
  for (const k in maxes) out[k] = to === 'lb' ? roundTo(maxes[k] * KG2LB, 5) : roundTo(maxes[k] / KG2LB, 2.5);
  return out;
}

/* ---------- small shared bits ---------- */
function SectionLabel({ children, style }) {
  return <div style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.08em', color: 'var(--text-3)', padding: '0 4px 10px', ...style }}>{children}</div>;
}
function ScreenHeader({ title, sub, action }) {
  return (
    <div style={{ padding: '8px 20px 6px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
      <div>
        {sub && <div style={{ fontSize: 13, color: 'var(--text-3)', fontWeight: 600, marginBottom: 3 }}>{sub}</div>}
        <h1 style={{ margin: 0, fontSize: 30, fontWeight: 700, letterSpacing: '-.02em', whiteSpace: 'nowrap' }}>{title}</h1>
      </div>
      {action}
    </div>
  );
}
function Screen({ children }) {
  return <div style={{ position: 'absolute', inset: 0, overflowY: 'auto', WebkitOverflowScrolling: 'touch', paddingTop: SAFE_TOP, paddingBottom: 40 }}>{children}</div>;
}
function PushScreen({ children }) {
  return <div style={{ position: 'absolute', inset: 0, zIndex: 30, background: 'var(--bg)', overflowY: 'auto', WebkitOverflowScrolling: 'touch', paddingBottom: 120, animation: 'pqSlideIn .28s cubic-bezier(.2,.8,.2,1)' }}>{children}</div>;
}
function ProgramGlyph({ text, size = 46, active }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: 'var(--r-md)', flexShrink: 0,
      background: active ? 'var(--accent)' : 'var(--accent-soft)', color: active ? 'var(--on-accent)' : 'var(--accent)',
      display: 'grid', placeItems: 'center', fontWeight: 800, letterSpacing: '-.02em',
      fontSize: text.length > 3 ? 13 : text.length > 2 ? 15 : 17, fontVariantNumeric: 'tabular-nums',
    }}>{text}</div>
  );
}

/* ---------- 1RM stepper (the hero control) ---------- */
function Stepper({ value, unit, onChange }) {
  const step = incFor(unit);
  const [str, setStr] = useState(fmtW(value));
  useEffect(() => { setStr(fmtW(value)); }, [value, unit]);
  const sqr = (child, onClick, disabled) => (
    <button onClick={onClick} disabled={disabled} style={{
      width: 38, height: 38, borderRadius: 'var(--r-xs)', border: 0, flexShrink: 0,
      background: 'var(--surface)', cursor: disabled ? 'default' : 'pointer', display: 'grid', placeItems: 'center',
      opacity: disabled ? 0.4 : 1, boxShadow: 'var(--shadow-sm)',
    }}>{child}</button>
  );
  const minus = <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 8h10" stroke="var(--text)" strokeWidth="2.2" strokeLinecap="round" /></svg>;
  const plus = <svg width="16" height="16" viewBox="0 0 16 16"><path d="M8 3v10M3 8h10" stroke="var(--accent)" strokeWidth="2.2" strokeLinecap="round" /></svg>;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: 5, border: '1px solid var(--hairline)' }}>
      {sqr(minus, () => onChange(Math.max(0, value - step)), value <= 0)}
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 3, minWidth: 90, justifyContent: 'center' }}>
        <input value={str} inputMode="decimal" onChange={(e) => { const v = e.target.value; setStr(v); const n = parseFloat(v); if (!isNaN(n)) onChange(n); }} onBlur={() => setStr(fmtW(value))}
          style={{ width: 60, border: 0, background: 'transparent', textAlign: 'right', fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 19, color: 'var(--text)', outline: 'none', padding: 0 }} />
        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)' }}>{unit}</span>
      </div>
      {sqr(plus, () => onChange(value + step))}
    </div>
  );
}

/* ---------- spreadsheet ---------- */
function SetCell({ w, set, unit, accent }) {
  const amrap = set.amrap, top = set.top || set.pr;
  const color = amrap ? 'var(--accent)' : 'var(--text)';
  return (
    <div style={{
      flex: 1, minWidth: 0, padding: '9px 4px', textAlign: 'center',
      background: top ? 'var(--accent-soft)' : amrap ? 'var(--accent-soft)' : 'transparent',
      borderRadius: 'var(--r-xs)',
    }}>
      <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 16, letterSpacing: '-.01em', color }}>{fmtW(w)}</div>
      <div style={{ fontSize: 10.5, fontWeight: 700, color: amrap ? 'var(--accent)' : 'var(--text-3)', marginTop: 2 }}>×{set.r}{amrap ? '+' : ''}</div>
    </div>
  );
}

function SpreadsheetTable({ prog, oneRM, tmPct, unit, warmups }) {
  const heads = prog.setHeads || prog.blocks[0].sets.map((_, i) => 'Set ' + (i + 1));
  const wuSets = warmups && prog.warmup ? prog.warmup.sets : (warmups ? [{ p: 0.4, r: 5 }, { p: 0.5, r: 5 }, { p: 0.6, r: 3 }] : null);
  const row = (key, label, sub, sets, opts = {}) => (
    <div key={key} style={{ display: 'flex', alignItems: 'stretch', borderTop: '1px solid var(--hairline)', background: opts.muted ? 'var(--surface-2)' : 'transparent' }}>
      <div style={{ width: 70, flexShrink: 0, padding: '8px 10px', display: 'flex', flexDirection: 'column', justifyContent: 'center', borderRight: '1px solid var(--hairline)' }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: opts.muted ? 'var(--text-3)' : 'var(--text)' }}>{label}</div>
        {sub && <div style={{ fontSize: 10.5, color: 'var(--text-3)', fontWeight: 600, marginTop: 1 }}>{sub}</div>}
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', padding: '2px 4px', gap: 2 }}>
        {sets.map((s, i) => <SetCell key={i} w={setWeight(oneRM, s.p, prog, tmPct, unit)} set={s} unit={unit} />)}
      </div>
    </div>
  );
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'stretch', background: 'var(--surface-2)' }}>
        <div style={{ width: 70, flexShrink: 0, padding: '9px 10px', fontSize: 11, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '.05em', borderRight: '1px solid var(--hairline)' }}>Week</div>
        <div style={{ flex: 1, display: 'flex', padding: '0 4px' }}>
          {heads.map((h, i) => <div key={i} style={{ flex: 1, textAlign: 'center', padding: '9px 2px', fontSize: 10.5, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '.04em' }}>{h}</div>)}
        </div>
      </div>
      {wuSets && row('wu', 'Warm-up', '', wuSets, { muted: true })}
      {prog.blocks.map((b, i) => row('b' + i, b.label, b.sub, b.sets))}
    </div>
  );
}

function SpreadsheetStraight({ prog, oneRM, tmPct, unit }) {
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
      {prog.blocks.map((b, i) => {
        const st = b.straight;
        const w = setWeight(oneRM, st.p, prog, tmPct, unit);
        return (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 700, fontSize: 15 }}>{b.label}</span>
                {b.sub && <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>{b.sub}</span>}
                {st.pr && <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> 5RM</Pill>}
              </div>
              <div style={{ marginTop: 4, fontSize: 13, color: 'var(--text-2)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
                {st.count} {st.count > 1 ? 'sets' : 'set'} × {st.r}{st.amrap ? '+' : ''} reps
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 22, letterSpacing: '-.02em', color: st.amrap || st.pr ? 'var(--accent)' : 'var(--text)' }}>{fmtW(w)}</span>
              <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 700 }}> {unit}</span>
            </div>
          </div>
        );
      })}
    </div>
  );
}

/* ---------- program detail ---------- */
function ProgramDetail({ prog, initialMaxes, unit, setUnit, tmPct, warmups, saved, onBack, onSave, onToast }) {
  const [maxes, setMaxes] = useState(initialMaxes);
  const [lift, setLift] = useState(prog.lifts[0]);
  const step = incFor(unit);
  const oneRM = maxes[lift];

  const setMax = (id, v) => setMaxes((m) => ({ ...m, [id]: v }));
  const switchUnit = (u) => { if (u === unit) return; setMaxes((m) => convertMaxes(m, u)); setUnit(u); };

  return (
    <PushScreen>
      {/* header */}
      <div style={{ position: 'sticky', top: 0, zIndex: 10, paddingTop: SAFE_TOP, background: 'color-mix(in srgb, var(--bg) 82%, transparent)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderBottom: '1px solid var(--hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 12px 12px', minHeight: 44 }}>
          <button onClick={onBack} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 38, height: 38, display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
            <Icon name="chevL" size={20} color="var(--text)" sw={2.4} />
          </button>
          <div style={{ fontWeight: 700, fontSize: 17, flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{prog.name}</div>
          {saved && <Pill tone="success"><Icon name="check" size={11} color="var(--success)" sw={3} /> Saved</Pill>}
        </div>
      </div>

      <div style={{ padding: '16px 16px 0' }}>
        {/* meta */}
        <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
          <ProgramGlyph text={prog.glyph} size={56} />
          <div style={{ flex: 1 }}>
            <div style={{ color: 'var(--text-3)', fontSize: 13, fontWeight: 600 }}>{prog.author}</div>
            <div style={{ display: 'flex', gap: 14, marginTop: 5, color: 'var(--text-2)', fontSize: 13, fontWeight: 600 }}>
              <span>{prog.days}</span><span>·</span><span>{prog.cycle}</span>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 9 }}>
              {prog.tags.map((t) => <Pill key={t} tone="accent">{t}</Pill>)}
            </div>
          </div>
        </div>
        <p style={{ margin: '16px 0 0', color: 'var(--text-2)', fontSize: 14, lineHeight: 1.55 }}>{prog.blurb}</p>

        {/* your maxes */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 26 }}>
          <SectionLabel style={{ padding: '0 4px 0' }}>{prog.usesTM ? 'Your 1RM → training max' : 'Your 1RM'}</SectionLabel>
          <div style={{ display: 'flex', background: 'var(--surface-2)', borderRadius: 'var(--r-full)', padding: 3, border: '1px solid var(--hairline)' }}>
            {['kg', 'lb'].map((u) => (
              <button key={u} onClick={() => switchUnit(u)} style={{ border: 0, cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '4px 12px', fontWeight: 700, fontSize: 12, fontFamily: 'var(--font)', background: unit === u ? 'var(--accent)' : 'transparent', color: unit === u ? 'var(--on-accent)' : 'var(--text-2)' }}>{u}</button>
            ))}
          </div>
        </div>
        <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden', marginTop: 10 }}>
          {prog.lifts.map((id, i) => {
            const tm = roundTo(maxes[id] * (tmPct / 100), step);
            const isActive = id === lift;
            return (
              <div key={id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 0, background: isActive && !prog.single ? 'var(--accent-tint)' : 'transparent' }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 15 }}>{TPL.lifts[id].name}</div>
                  {prog.usesTM && <div style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>Training max <span style={{ color: 'var(--accent)' }}>{fmtW(tm)} {unit}</span> · {tmPct}%</div>}
                </div>
                <Stepper value={maxes[id]} unit={unit} onChange={(v) => setMax(id, v)} />
              </div>
            );
          })}
        </div>

        {/* spreadsheet */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 26 }}>
          <SectionLabel style={{ padding: '0 4px 0' }}>Your plan</SectionLabel>
          <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>Live · rounds to {step} {unit}</span>
        </div>

        {/* lift selector */}
        {!prog.single && prog.lifts.length > 1 && (
          <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '2px 2px 12px', margin: '0 -2px' }}>
            {prog.lifts.map((id) => {
              const a = id === lift;
              return (
                <button key={id} onClick={() => setLift(id)} style={{ flexShrink: 0, border: '1px solid ' + (a ? 'transparent' : 'var(--hairline)'), cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '7px 14px', fontWeight: 700, fontSize: 13, fontFamily: 'var(--font)', background: a ? 'var(--accent)' : 'var(--surface)', color: a ? 'var(--on-accent)' : 'var(--text-2)', whiteSpace: 'nowrap' }}>{TPL.lifts[id].name}</button>
              );
            })}
          </div>
        )}

        <div style={{ marginTop: prog.single || prog.lifts.length <= 1 ? 10 : 0 }}>
          {prog.layout === 'table'
            ? <SpreadsheetTable prog={prog} oneRM={oneRM} tmPct={tmPct} unit={unit} warmups={warmups} />
            : <SpreadsheetStraight prog={prog} oneRM={oneRM} tmPct={tmPct} unit={unit} />}
        </div>

        {/* supplemental */}
        {prog.supplemental && (
          <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 12, background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', padding: '14px 16px' }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 14 }}>{prog.supplemental.label}</div>
              <div style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600, marginTop: 2 }}>{prog.supplemental.detail} · same lift</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 20 }}>{fmtW(setWeight(oneRM, prog.supplemental.p, prog, tmPct, unit))}</span>
              <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 700 }}> {unit}</span>
            </div>
          </div>
        )}

        {/* legend / notes */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 12, padding: '0 2px', flexWrap: 'wrap' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>
            <span style={{ width: 16, height: 16, borderRadius: 4, background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', color: 'var(--accent)', fontWeight: 800, fontSize: 11 }}>+</span> AMRAP — as many reps as possible
          </span>
        </div>
        {prog.note && <p style={{ margin: '12px 2px 0', color: 'var(--text-3)', fontSize: 12.5, lineHeight: 1.5 }}>{prog.note}</p>}

        {/* progression */}
        <div style={{ marginTop: 18, display: 'flex', gap: 12, alignItems: 'flex-start', background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', borderLeft: '3px solid var(--accent)', padding: '14px 16px' }}>
          <Icon name="arrowUp" size={18} color="var(--accent)" sw={2.2} style={{ flexShrink: 0, marginTop: 1 }} />
          <div>
            <div style={{ fontWeight: 700, fontSize: 13.5 }}>How it progresses</div>
            <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 3, lineHeight: 1.5 }}>{prog.progressNote}</div>
          </div>
        </div>
      </div>

      {/* sticky save bar */}
      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '14px 16px 26px', background: 'linear-gradient(to top, var(--bg) 62%, transparent)', display: 'flex', gap: 10 }}>
        <Btn onClick={() => onSave(prog, maxes, unit)} variant={saved ? 'ghost' : 'primary'}>
          {saved ? <><Icon name="check" size={17} color="var(--text)" sw={2.4} /> Update saved plan</> : <><Icon name="plus" size={17} color="var(--on-accent)" sw={2.4} /> Save to my library</>}
        </Btn>
      </div>
    </PushScreen>
  );
}

/* ---------- library (browse) ---------- */
function ProgramCard({ prog, onOpen, saved }) {
  return (
    <button onClick={onOpen} style={{ width: '100%', textAlign: 'left', border: '1px solid var(--hairline)', background: 'var(--surface)', borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow)', padding: 'var(--s5)', cursor: 'pointer', fontFamily: 'var(--font)', display: 'flex', gap: 14, alignItems: 'flex-start' }}>
      <ProgramGlyph text={prog.glyph} size={46} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontWeight: 700, fontSize: 16, color: 'var(--text)' }}>{prog.name}</span>
          {saved && <Icon name="check" size={15} color="var(--success)" sw={2.6} />}
        </div>
        <div style={{ color: 'var(--text-3)', fontSize: 12.5, fontWeight: 600, marginTop: 2 }}>{prog.author}</div>
        <div style={{ display: 'flex', gap: 12, marginTop: 9, color: 'var(--text-2)', fontSize: 12.5, fontWeight: 600 }}>
          <span>{prog.days}</span><span style={{ color: 'var(--text-3)' }}>·</span><span>{prog.cycle}</span>
        </div>
      </div>
      <Icon name="chevR" size={18} color="var(--text-3)" style={{ marginTop: 4 }} />
    </button>
  );
}

function LibraryScreen({ library, unit, onOpen, onOpenSaved }) {
  const [q, setQ] = useState('');
  const [cat, setCat] = useState('All');
  const list = TPL.programs.filter((p) =>
    (cat === 'All' || p.tags.includes(cat)) &&
    p.name.toLowerCase().includes(q.toLowerCase()));
  const savedIds = new Set(library.map((s) => s.programId));

  return (
    <Screen>
      <ScreenHeader sub="Program library" title="Templates" />
      <div style={{ padding: '12px 16px 0' }}>
        {/* search */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: '10px 13px' }}>
          <Icon name="search" size={18} color="var(--text-3)" />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search programs" style={{ border: 0, background: 'transparent', color: 'var(--text)', fontSize: 16, outline: 'none', flex: 1, fontFamily: 'var(--font)' }} />
        </div>
        {/* category chips */}
        <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '12px 2px 4px', margin: '0 -2px' }}>
          {TPL.categories.map((c) => {
            const a = c === cat;
            return <button key={c} onClick={() => setCat(c)} style={{ flexShrink: 0, border: '1px solid ' + (a ? 'transparent' : 'var(--hairline)'), cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '7px 14px', fontWeight: 700, fontSize: 13, fontFamily: 'var(--font)', background: a ? 'var(--accent)' : 'var(--surface)', color: a ? 'var(--on-accent)' : 'var(--text-2)', whiteSpace: 'nowrap' }}>{c}</button>;
          })}
        </div>

        {/* my library */}
        {library.length > 0 && (
          <div style={{ marginTop: 18 }}>
            <SectionLabel>In your library</SectionLabel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {library.map((s) => {
                const prog = TPL.programs.find((p) => p.id === s.programId);
                if (!prog) return null;
                const top = prog.lifts.map((id) => `${TPL.lifts[id].short} ${fmtW(s.maxes[id])}`).slice(0, 3).join(' · ');
                return (
                  <button key={s.id} onClick={() => onOpenSaved(s)} style={{ width: '100%', textAlign: 'left', border: '1px solid var(--hairline)', background: 'var(--surface)', borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow)', padding: 'var(--s5)', cursor: 'pointer', fontFamily: 'var(--font)', display: 'flex', gap: 14, alignItems: 'center' }}>
                    <ProgramGlyph text={prog.glyph} size={46} active />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 700, fontSize: 16 }}>{prog.name}</div>
                      <div style={{ color: 'var(--text-2)', fontSize: 12.5, fontWeight: 600, marginTop: 3, fontVariantNumeric: 'tabular-nums' }}>{top} <span style={{ color: 'var(--text-3)' }}>{s.unit}</span></div>
                    </div>
                    <div style={{ width: 38, height: 38, borderRadius: 'var(--r-xs)', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                      <Icon name="play" size={16} color="var(--accent)" fill />
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* browse */}
        <SectionLabel style={{ marginTop: 22 }}>{cat === 'All' ? 'Built-in programs' : cat}</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {list.map((p) => <ProgramCard key={p.id} prog={p} saved={savedIds.has(p.id)} onOpen={() => onOpen(p)} />)}
          {list.length === 0 && <div style={{ textAlign: 'center', color: 'var(--text-3)', fontSize: 14, padding: '28px 0' }}>No programs match.</div>}
        </div>
        <p style={{ margin: '18px 2px 0', color: 'var(--text-3)', fontSize: 12.5, lineHeight: 1.5, textAlign: 'center' }}>Every template builds from your 1RM. Tweak your numbers any time and the whole plan recalculates.</p>
      </div>
    </Screen>
  );
}

/* ---------- toast ---------- */
function Toast({ msg }) {
  if (!msg) return null;
  return <div style={{ position: 'absolute', bottom: 96, left: '50%', transform: 'translateX(-50%)', zIndex: 80, background: 'var(--surface)', color: 'var(--text)', borderRadius: 'var(--r-full)', padding: '11px 18px', fontWeight: 600, fontSize: 14, whiteSpace: 'nowrap', boxShadow: 'var(--shadow-lg)', border: '1px solid var(--hairline)', animation: 'pqUp .25s ease' }}>{msg}</div>;
}

/* ---------- root ---------- */
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#3B7BF6",
  "appearance": "dark",
  "typeface": "System",
  "corners": "Default",
  "density": "Regular",
  "trainingMax": 90,
  "warmups": false
}/*EDITMODE-END*/;

const FONTS = { System: '-apple-system, "SF Pro Text", system-ui, sans-serif', Plex: '"IBM Plex Sans", system-ui, sans-serif', Display: '"Space Grotesk", system-ui, sans-serif' };
const RSCALE = { Sharp: 0.5, Default: 1, Rounded: 1.5 };
const DSCALE = { Compact: 0.9, Regular: 1, Roomy: 1.14 };
const ACCENTS = ['#3B7BF6', '#F26A1B', '#7C5CFF', '#17A86B'];
const LIB_KEY = 'pq_template_lib_lb_v1';

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [unit, setUnit] = useState('lb');
  const [detail, setDetail] = useState(null); // { prog, maxes }
  const [toast, setToast] = useState(null);
  const toastT = useRef(null);
  const [library, setLibrary] = useState(() => {
    try { const v = JSON.parse(localStorage.getItem(LIB_KEY)); if (Array.isArray(v)) return v; } catch (e) {}
    return [{ id: 'seed1', programId: 'gzclp', unit: 'lb', maxes: { ...TPL.defaults.lb }, savedAt: Date.now() }];
  });

  useEffect(() => { try { localStorage.setItem(LIB_KEY, JSON.stringify(library)); } catch (e) {} }, [library]);

  const showToast = (m) => { setToast(m); clearTimeout(toastT.current); toastT.current = setTimeout(() => setToast(null), 2400); };

  const openProgram = (prog) => setDetail({ prog, maxes: { ...TPL.defaults[unit] } });
  const openSaved = (s) => { setUnit(s.unit); setDetail({ prog: TPL.programs.find((p) => p.id === s.programId), maxes: { ...s.maxes } }); };

  const savePlan = (prog, maxes, u) => {
    setLibrary((lib) => {
      const existing = lib.find((s) => s.programId === prog.id);
      if (existing) return lib.map((s) => s.programId === prog.id ? { ...s, maxes: { ...maxes }, unit: u, savedAt: Date.now() } : s);
      return [{ id: 'lib' + Date.now(), programId: prog.id, unit: u, maxes: { ...maxes }, savedAt: Date.now() }, ...lib];
    });
    showToast(library.some((s) => s.programId === prog.id) ? 'Updated in your library' : `Saved · ${prog.name}`);
  };

  const isDark = t.appearance === 'dark';
  const rootStyle = { '--accent': t.accent, '--on-accent': '#ffffff', '--r-scale': RSCALE[t.corners] ?? 1, '--d-scale': DSCALE[t.density] ?? 1, fontFamily: FONTS[t.typeface] || FONTS.System };
  const savedSet = new Set(library.map((s) => s.programId));

  return (
    <div>
      <IOSDevice dark={isDark} width={402} height={874}>
        <div className="pq-root" data-theme={t.appearance} style={rootStyle}>
          <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)', color: 'var(--text)' }}>
            <LibraryScreen library={library} unit={unit} onOpen={openProgram} onOpenSaved={openSaved} />
            {detail && (
              <ProgramDetail
                key={detail.prog.id + detail.maxes[detail.prog.lifts[0]]}
                prog={detail.prog} initialMaxes={detail.maxes} unit={unit} setUnit={setUnit}
                tmPct={t.trainingMax} warmups={t.warmups} saved={savedSet.has(detail.prog.id)}
                onBack={() => setDetail(null)} onSave={savePlan} onToast={showToast} />
            )}
            <Toast msg={toast} />
          </div>
        </div>
      </IOSDevice>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Appearance" />
        <TweakRadio label="Theme" value={t.appearance} options={['dark', 'light']} onChange={(v) => setTweak('appearance', v)} />
        <TweakColor label="Accent" value={t.accent} options={ACCENTS} onChange={(v) => setTweak('accent', v)} />
        <TweakSection label="Program math" />
        <TweakSlider label="Training max" value={t.trainingMax} min={80} max={100} step={2.5} unit="%" onChange={(v) => setTweak('trainingMax', v)} />
        <TweakToggle label="Warm-up sets" value={t.warmups} onChange={(v) => setTweak('warmups', v)} />
        <TweakSection label="Type & shape" />
        <TweakRadio label="Typeface" value={t.typeface} options={['System', 'Plex', 'Display']} onChange={(v) => setTweak('typeface', v)} />
        <TweakRadio label="Corners" value={t.corners} options={['Sharp', 'Default', 'Rounded']} onChange={(v) => setTweak('corners', v)} />
        <TweakRadio label="Density" value={t.density} options={['Compact', 'Regular', 'Roomy']} onChange={(v) => setTweak('density', v)} />
        <TweakSection label="Library" />
        <TweakButton label="Clear saved library" onClick={() => { setLibrary([]); showToast('Library cleared'); }} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
