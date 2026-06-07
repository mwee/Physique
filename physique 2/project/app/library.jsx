/* PHYSIQUE — Template library, integrated into the app.
   Provides: the browse screen, the program detail (enter & tweak 1RM → live
   spreadsheet), and the scheduling engine that turns an activated program into
   specific, startable ActiveWorkout sessions.
   Reuses window globals from the rest of the app: Icon, Btn, Card, Pill,
   SectionLabel, ScreenHeader, PushScreen, PushHeader, SAFE_TOP. */
const { useState: useStateL } = React;

/* ---------- math ---------- */
const tplInc = 5;
const tplRound = (x) => Math.round(x / tplInc) * tplInc;
const tplFmt = (x) => (Number.isInteger(x) ? String(x) : (Math.round(x * 10) / 10).toFixed(1).replace(/\.0$/, ''));
function tplBasis(prog, oneRM, tmPct) { return prog.basis === 'tm' ? tplRound(oneRM * (tmPct / 100)) : oneRM; }
function tplSet(prog, oneRM, p, tmPct) { return tplRound(tplBasis(prog, oneRM, tmPct) * p); }
function tplScale(prog, w, week, light) {
  if (prog.weekScale === 'mult') { let m = 1 + 0.025 * week; if (light) m *= 0.9; return tplRound(w * m); }
  if (prog.weekScale === 'add') return tplRound(w + week * tplInc);
  if (light) return tplRound(w * 0.9);
  return w;
}
function tplBlockFor(prog, b, week) { return prog.useWeekBlock ? prog.blocks[week] : prog.blocks[b]; }

/* ---------- scheduling engine ---------- */
function tplSessionExercises(prog, day, week, maxes, tmPct, warmups) {
  const units = day.items ? day.items.map((it) => ({ id: it.id, b: it.b })) : day.ids.map((id) => ({ id, b: day.b || 0 }));
  const out = [];
  units.forEach((u) => {
    const block = tplBlockFor(prog, u.b, week);
    const oneRM = maxes[u.id];
    const sets = [];
    let amrap = false;
    if (warmups && prog.warmup) prog.warmup.sets.forEach((s) => sets.push({ type: 'W', prev: null, w: tplScale(prog, tplSet(prog, oneRM, s.p, tmPct), week, day.light), r: s.r, done: false }));
    if (block.sets) {
      block.sets.forEach((s, i) => { if (s.amrap) amrap = true; sets.push({ type: i + 1, prev: null, w: tplScale(prog, tplSet(prog, oneRM, s.p, tmPct), week, day.light), r: s.r, done: false }); });
    } else if (block.straight) {
      const st = block.straight; const w = tplScale(prog, tplSet(prog, oneRM, st.p, tmPct), week, day.light);
      for (let i = 0; i < st.count; i++) { if (st.amrap && i === st.count - 1) amrap = true; sets.push({ type: i + 1, prev: null, w, r: st.r, done: false }); }
    }
    const ex = { name: TPL.lifts[u.id].name, sets };
    if (amrap) ex.note = 'Last set is AMRAP — beat your rep target.';
    out.push(ex);
    if (prog.supplemental && prog.useWeekBlock) {
      const w = tplSet(prog, oneRM, prog.supplemental.p, tmPct);
      const ss = []; for (let i = 0; i < 5; i++) ss.push({ type: i + 1, prev: null, w, r: 10, done: false });
      out.push({ name: TPL.lifts[u.id].name + ' · BBB', sets: ss });
    }
  });
  return out;
}

function tplBuildSessionPlan(active, dayIndex) {
  const prog = TPL.programs.find((p) => p.id === active.programId);
  const day = prog.split[dayIndex];
  const week = active.week || 0;
  const exercises = tplSessionExercises(prog, day, week, active.maxes, active.tmPct || 90, active.warmups);
  const wk = prog.waved && prog.cycleWeeks > 1 ? ` · Wk ${week + 1}` : '';
  return { title: day.name + wk, exercises };
}

function tplScheduleDays(active) {
  const prog = TPL.programs.find((p) => p.id === active.programId);
  const week = active.week || 0;
  return prog.split.map((day, i) => {
    const exs = tplSessionExercises(prog, day, week, active.maxes, active.tmPct || 90, false);
    const main = exs[0];
    const work = main.sets.filter((s) => s.type !== 'W');
    const top = work.reduce((a, s) => (s.w >= a.w ? s : a), work[0]);
    const lifts = [...new Set(exs.filter((e) => !/· BBB$/.test(e.name)).map((e) => e.name))];
    const setCount = exs.reduce((a, e) => a + e.sets.length, 0);
    return { index: i, name: day.name, sub: day.sub, lifts, top: { w: top.w, r: top.r, amrap: !!main.note }, setCount, est: Math.max(20, Math.round(setCount * 3)) };
  });
}

/* ---------- shared bits ---------- */
function ProgramGlyph({ text, size = 46, active }) {
  return (
    <div style={{ width: size, height: size, borderRadius: 'var(--r-md)', flexShrink: 0, background: active ? 'var(--accent)' : 'var(--accent-soft)', color: active ? 'var(--on-accent)' : 'var(--accent)', display: 'grid', placeItems: 'center', fontWeight: 800, letterSpacing: '-.02em', fontSize: text.length > 3 ? 13 : text.length > 2 ? 15 : 17, fontVariantNumeric: 'tabular-nums' }}>{text}</div>
  );
}

function LibStepper({ value, onChange }) {
  const [str, setStr] = useStateL(tplFmt(value));
  React.useEffect(() => { setStr(tplFmt(value)); }, [value]);
  const sqr = (child, onClick, disabled) => (
    <button onClick={onClick} disabled={disabled} style={{ width: 38, height: 38, borderRadius: 'var(--r-xs)', border: 0, flexShrink: 0, background: 'var(--surface)', cursor: disabled ? 'default' : 'pointer', display: 'grid', placeItems: 'center', opacity: disabled ? 0.4 : 1, boxShadow: 'var(--shadow-sm)' }}>{child}</button>
  );
  const minus = <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 8h10" stroke="var(--text)" strokeWidth="2.2" strokeLinecap="round" /></svg>;
  const plus = <svg width="16" height="16" viewBox="0 0 16 16"><path d="M8 3v10M3 8h10" stroke="var(--accent)" strokeWidth="2.2" strokeLinecap="round" /></svg>;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: 5, border: '1px solid var(--hairline)' }}>
      {sqr(minus, () => onChange(Math.max(0, value - tplInc)), value <= 0)}
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 3, minWidth: 84, justifyContent: 'center' }}>
        <input value={str} inputMode="decimal" onChange={(e) => { const v = e.target.value; setStr(v); const n = parseFloat(v); if (!isNaN(n)) onChange(n); }} onBlur={() => setStr(tplFmt(value))} style={{ width: 60, border: 0, background: 'transparent', textAlign: 'right', fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 19, color: 'var(--text)', outline: 'none', padding: 0 }} />
        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-3)' }}>lb</span>
      </div>
      {sqr(plus, () => onChange(value + tplInc))}
    </div>
  );
}

/* ---------- spreadsheet preview ---------- */
function TplSetCell({ w, set }) {
  const amrap = set.amrap, top = set.top || set.pr;
  return (
    <div style={{ flex: 1, minWidth: 0, padding: '9px 4px', textAlign: 'center', background: top || amrap ? 'var(--accent-soft)' : 'transparent', borderRadius: 'var(--r-xs)' }}>
      <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 16, letterSpacing: '-.01em', color: amrap ? 'var(--accent)' : 'var(--text)' }}>{tplFmt(w)}</div>
      <div style={{ fontSize: 10.5, fontWeight: 700, color: amrap ? 'var(--accent)' : 'var(--text-3)', marginTop: 2 }}>×{set.r}{amrap ? '+' : ''}</div>
    </div>
  );
}
function TplSpreadTable({ prog, oneRM, tmPct, warmups }) {
  const heads = prog.setHeads || prog.blocks[0].sets.map((_, i) => 'Set ' + (i + 1));
  const wuSets = warmups && prog.warmup ? prog.warmup.sets : null;
  const row = (key, label, sub, sets, muted) => (
    <div key={key} style={{ display: 'flex', alignItems: 'stretch', borderTop: '1px solid var(--hairline)', background: muted ? 'var(--surface-2)' : 'transparent' }}>
      <div style={{ width: 70, flexShrink: 0, padding: '8px 10px', display: 'flex', flexDirection: 'column', justifyContent: 'center', borderRight: '1px solid var(--hairline)' }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: muted ? 'var(--text-3)' : 'var(--text)' }}>{label}</div>
        {sub && <div style={{ fontSize: 10.5, color: 'var(--text-3)', fontWeight: 600, marginTop: 1 }}>{sub}</div>}
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', padding: '2px 4px', gap: 2 }}>
        {sets.map((s, i) => <TplSetCell key={i} w={tplSet(prog, oneRM, s.p, tmPct)} set={s} />)}
      </div>
    </div>
  );
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
      <div style={{ display: 'flex', alignItems: 'stretch', background: 'var(--surface-2)' }}>
        <div style={{ width: 70, flexShrink: 0, padding: '9px 10px', fontSize: 11, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '.05em', borderRight: '1px solid var(--hairline)' }}>{prog.useWeekBlock ? 'Week' : 'Set'}</div>
        <div style={{ flex: 1, display: 'flex', padding: '0 4px' }}>
          {heads.map((h, i) => <div key={i} style={{ flex: 1, textAlign: 'center', padding: '9px 2px', fontSize: 10.5, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: '.04em' }}>{h}</div>)}
        </div>
      </div>
      {wuSets && row('wu', 'Warm-up', '', wuSets, true)}
      {prog.blocks.map((b, i) => row('b' + i, b.label, b.sub, b.sets))}
    </div>
  );
}
function TplSpreadStraight({ prog, oneRM, tmPct }) {
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
      {prog.blocks.map((b, i) => {
        const st = b.straight; const w = tplSet(prog, oneRM, st.p, tmPct);
        return (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 700, fontSize: 15 }}>{b.label}</span>
                {b.sub && <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>{b.sub}</span>}
                {st.pr && <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> 5RM</Pill>}
              </div>
              <div style={{ marginTop: 4, fontSize: 13, color: 'var(--text-2)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{st.count} {st.count > 1 ? 'sets' : 'set'} × {st.r}{st.amrap ? '+' : ''} reps</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 22, letterSpacing: '-.02em', color: st.amrap || st.pr ? 'var(--accent)' : 'var(--text)' }}>{tplFmt(w)}</span>
              <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 700 }}> lb</span>
            </div>
          </div>
        );
      })}
    </div>
  );
}

/* ---------- program detail ---------- */
function ProgramDetailScreen({ prog, initial, onBack, onActivate }) {
  const isActive = !!initial && initial.programId === prog.id;
  const [maxes, setMaxes] = useStateL(() => (initial ? { ...initial.maxes } : { ...TPL.defaults.lb }));
  const [tmPct, setTmPct] = useStateL(() => (initial ? initial.tmPct || 90 : 90));
  const [warmups, setWarmups] = useStateL(() => (initial ? !!initial.warmups : false));
  const [lift, setLift] = useStateL(prog.lifts[0]);
  const oneRM = maxes[lift];
  const setMax = (id, v) => setMaxes((m) => ({ ...m, [id]: v }));

  return (
    <PushScreen>
      <PushHeader title={prog.name} onBack={onBack} trailing={isActive ? <Pill tone="success"><Icon name="check" size={11} color="var(--success)" sw={3} /> Active</Pill> : null} />
      <div style={{ padding: '16px 16px 0' }}>
        <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
          <ProgramGlyph text={prog.glyph} size={56} />
          <div style={{ flex: 1 }}>
            <div style={{ color: 'var(--text-3)', fontSize: 13, fontWeight: 600 }}>{prog.author}</div>
            <div style={{ display: 'flex', gap: 14, marginTop: 5, color: 'var(--text-2)', fontSize: 13, fontWeight: 600 }}><span>{prog.days}</span><span>·</span><span>{prog.cycle}</span></div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 9 }}>{prog.tags.map((t) => <Pill key={t} tone="accent">{t}</Pill>)}</div>
          </div>
        </div>
        <p style={{ margin: '16px 0 0', color: 'var(--text-2)', fontSize: 14, lineHeight: 1.55 }}>{prog.blurb}</p>

        <SectionLabel style={{ marginTop: 26 }}>{prog.usesTM ? 'Your 1RM → training max' : 'Your 1RM'}</SectionLabel>
        <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
          {prog.lifts.map((id, i) => {
            const tm = tplRound(maxes[id] * (tmPct / 100));
            const a = id === lift && !prog.single;
            return (
              <div key={id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderTop: i ? '1px solid var(--hairline)' : 0, background: a ? 'var(--accent-tint)' : 'transparent' }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 15 }}>{TPL.lifts[id].name}</div>
                  {prog.usesTM && <div style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>Training max <span style={{ color: 'var(--accent)' }}>{tplFmt(tm)} lb</span> · {tmPct}%</div>}
                </div>
                <LibStepper value={maxes[id]} onChange={(v) => setMax(id, v)} />
              </div>
            );
          })}
        </div>

        {/* options */}
        <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
          {prog.usesTM && (
            <div style={{ flex: 1, background: 'var(--surface)', borderRadius: 'var(--r-sm)', border: '1px solid var(--hairline)', padding: '10px 12px' }}>
              <div style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: 7 }}>Training max</div>
              <div style={{ display: 'flex', background: 'var(--surface-2)', borderRadius: 'var(--r-xs)', padding: 3, gap: 3 }}>
                {[85, 90, 95].map((p) => <button key={p} onClick={() => setTmPct(p)} style={{ flex: 1, border: 0, cursor: 'pointer', borderRadius: 'var(--r-xs)', padding: '6px 0', fontWeight: 700, fontSize: 13, fontFamily: 'var(--font)', background: tmPct === p ? 'var(--accent)' : 'transparent', color: tmPct === p ? 'var(--on-accent)' : 'var(--text-2)' }}>{p}%</button>)}
              </div>
            </div>
          )}
          {prog.warmup && (
            <button onClick={() => setWarmups((w) => !w)} style={{ flex: 1, textAlign: 'left', background: 'var(--surface)', borderRadius: 'var(--r-sm)', border: '1px solid var(--hairline)', padding: '10px 12px', cursor: 'pointer', fontFamily: 'var(--font)' }}>
              <div style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em', marginBottom: 7 }}>Warm-up sets</div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ fontWeight: 700, fontSize: 14, color: warmups ? 'var(--accent)' : 'var(--text-2)' }}>{warmups ? 'Included' : 'Off'}</span>
                <div style={{ width: 38, height: 22, borderRadius: 'var(--r-full)', background: warmups ? 'var(--accent)' : 'var(--surface-3)', position: 'relative', transition: 'background .15s' }}>
                  <div style={{ position: 'absolute', top: 2, left: warmups ? 18 : 2, width: 18, height: 18, borderRadius: '50%', background: '#fff', transition: 'left .15s' }} />
                </div>
              </div>
            </button>
          )}
        </div>

        {/* spreadsheet */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 24 }}>
          <SectionLabel style={{ padding: '0 4px 0' }}>The plan</SectionLabel>
          <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>Live · rounds to 5 lb</span>
        </div>
        {!prog.single && prog.lifts.length > 1 && (
          <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '2px 2px 12px', margin: '0 -2px' }}>
            {prog.lifts.map((id) => { const a = id === lift; return <button key={id} onClick={() => setLift(id)} style={{ flexShrink: 0, border: '1px solid ' + (a ? 'transparent' : 'var(--hairline)'), cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '7px 14px', fontWeight: 700, fontSize: 13, fontFamily: 'var(--font)', background: a ? 'var(--accent)' : 'var(--surface)', color: a ? 'var(--on-accent)' : 'var(--text-2)', whiteSpace: 'nowrap' }}>{TPL.lifts[id].name}</button>; })}
          </div>
        )}
        <div style={{ marginTop: prog.single || prog.lifts.length <= 1 ? 10 : 0 }}>
          {prog.layout === 'table' ? <TplSpreadTable prog={prog} oneRM={oneRM} tmPct={tmPct} warmups={warmups} /> : <TplSpreadStraight prog={prog} oneRM={oneRM} tmPct={tmPct} />}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 12, padding: '0 2px' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}>
            <span style={{ width: 16, height: 16, borderRadius: 4, background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', color: 'var(--accent)', fontWeight: 800, fontSize: 11 }}>+</span> AMRAP — as many reps as possible
          </span>
        </div>
        {prog.note && <p style={{ margin: '12px 2px 0', color: 'var(--text-3)', fontSize: 12.5, lineHeight: 1.5 }}>{prog.note}</p>}

        <div style={{ marginTop: 18, display: 'flex', gap: 12, alignItems: 'flex-start', background: 'var(--surface)', borderRadius: 'var(--r-md)', border: '1px solid var(--hairline)', borderLeft: '3px solid var(--accent)', padding: '14px 16px' }}>
          <Icon name="arrowUp" size={18} color="var(--accent)" sw={2.2} style={{ flexShrink: 0, marginTop: 1 }} />
          <div><div style={{ fontWeight: 700, fontSize: 13.5 }}>How it progresses</div><div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 3, lineHeight: 1.5 }}>{prog.progressNote}</div></div>
        </div>
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '14px 16px 26px', background: 'linear-gradient(to top, var(--bg) 62%, transparent)' }}>
        <Btn onClick={() => onActivate({ programId: prog.id, maxes, tmPct, warmups, week: isActive ? (initial.week || 0) : 0 })}>
          {isActive ? <><Icon name="check" size={17} color="var(--on-accent)" sw={2.4} /> Update my plan</> : <><Icon name="calendar" size={17} color="var(--on-accent)" /> Use this program</>}
        </Btn>
      </div>
    </PushScreen>
  );
}

/* ---------- browse ---------- */
function ProgramCard({ prog, onOpen, active }) {
  return (
    <button onClick={onOpen} style={{ width: '100%', textAlign: 'left', border: '1px solid var(--hairline)', background: 'var(--surface)', borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow)', padding: 'var(--s5)', cursor: 'pointer', fontFamily: 'var(--font)', display: 'flex', gap: 14, alignItems: 'flex-start' }}>
      <ProgramGlyph text={prog.glyph} size={46} active={active} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontWeight: 700, fontSize: 16, color: 'var(--text)' }}>{prog.name}</span>
          {active && <Pill tone="success">Active</Pill>}
        </div>
        <div style={{ color: 'var(--text-3)', fontSize: 12.5, fontWeight: 600, marginTop: 2 }}>{prog.author}</div>
        <div style={{ display: 'flex', gap: 12, marginTop: 9, color: 'var(--text-2)', fontSize: 12.5, fontWeight: 600 }}><span>{prog.days}</span><span style={{ color: 'var(--text-3)' }}>·</span><span>{prog.cycle}</span></div>
      </div>
      <Icon name="chevR" size={18} color="var(--text-3)" style={{ marginTop: 4 }} />
    </button>
  );
}

function LibraryBrowseScreen({ activeId, onBack, onOpen }) {
  const [q, setQ] = useStateL('');
  const [cat, setCat] = useStateL('All');
  const list = TPL.programs.filter((p) => (cat === 'All' || p.tags.includes(cat)) && p.name.toLowerCase().includes(q.toLowerCase()));
  return (
    <PushScreen>
      <PushHeader title="Template library" onBack={onBack} />
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: '10px 13px' }}>
          <Icon name="search" size={18} color="var(--text-3)" />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search programs" style={{ border: 0, background: 'transparent', color: 'var(--text)', fontSize: 16, outline: 'none', flex: 1, fontFamily: 'var(--font)' }} />
        </div>
        <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '12px 2px 4px', margin: '0 -2px' }}>
          {TPL.categories.map((c) => { const a = c === cat; return <button key={c} onClick={() => setCat(c)} style={{ flexShrink: 0, border: '1px solid ' + (a ? 'transparent' : 'var(--hairline)'), cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '7px 14px', fontWeight: 700, fontSize: 13, fontFamily: 'var(--font)', background: a ? 'var(--accent)' : 'var(--surface)', color: a ? 'var(--on-accent)' : 'var(--text-2)', whiteSpace: 'nowrap' }}>{c}</button>; })}
        </div>
        <SectionLabel style={{ marginTop: 18 }}>{cat === 'All' ? 'Built-in programs' : cat}</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {list.map((p) => <ProgramCard key={p.id} prog={p} active={p.id === activeId} onOpen={() => onOpen(p)} />)}
          {list.length === 0 && <div style={{ textAlign: 'center', color: 'var(--text-3)', fontSize: 14, padding: '28px 0' }}>No programs match.</div>}
        </div>
        <p style={{ margin: '18px 2px 40px', color: 'var(--text-3)', fontSize: 12.5, lineHeight: 1.5, textAlign: 'center' }}>Every template builds from your 1RM. Pick one, dial in your numbers, and it schedules your workouts automatically.</p>
      </div>
    </PushScreen>
  );
}

Object.assign(window, { tplBuildSessionPlan, tplScheduleDays, ProgramGlyph, ProgramDetailScreen, LibraryBrowseScreen, tplFmt });
