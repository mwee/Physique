/* PHYSIQUE — Active Workout (the hero), numeric keypad, rest timer */
const { useState, useEffect, useRef } = React;

const SAFE_TOP = 56;
const fmtTime = (s) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

// ---------- Elapsed workout clock (isolated so parent doesn't re-render each second) ----------
function Elapsed({ base, startRef }) {
  const [sec, setSec] = useState(base);
  useEffect(() => { const t = setInterval(() => setSec(base + Math.floor((Date.now() - startRef.current) / 1000)), 1000); return () => clearInterval(t); }, []);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 16, color: 'var(--accent)', fontWeight: 600, marginTop: 5 }}>
      <Icon name="clock" size={15} color="var(--accent)" /> {fmtTime(sec)}
    </div>
  );
}

// ---------- Rest timer pill (self-managing countdown) ----------
function RestPill({ total, onDone }) {
  const [open, setOpen] = useState(false);
  const [remaining, setRemaining] = useState(total);
  const [tot, setTot] = useState(total);
  useEffect(() => {
    if (remaining <= 0) { onDone(); return; }
    const t = setTimeout(() => setRemaining(x => x - 1), 1000);
    return () => clearTimeout(t);
  }, [remaining]);
  const onAdd = (d) => { setRemaining(x => Math.max(0, x + d)); setTot(x => Math.max(x, remaining + d)); };
  const onSkip = () => onDone();
  const r = 13, c = 2 * Math.PI * r;
  const frac = tot ? remaining / tot : 0;
  return (
    <div style={{ position: 'relative' }}>
      <button onClick={() => setOpen(o => !o)} style={{
        display: 'flex', alignItems: 'center', gap: 9, border: 0, cursor: 'pointer',
        background: 'var(--accent)', color: 'var(--on-accent)', padding: '8px 14px 8px 9px',
        borderRadius: 'var(--r-full)', fontWeight: 700, fontSize: 16,
        fontVariantNumeric: 'tabular-nums', boxShadow: '0 6px 18px var(--accent-soft)',
      }}>
        <svg width="30" height="30" viewBox="0 0 30 30">
          <circle cx="15" cy="15" r={r} fill="none" stroke="rgba(255,255,255,0.3)" strokeWidth="3" />
          <circle cx="15" cy="15" r={r} fill="none" stroke="#fff" strokeWidth="3"
            strokelinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - frac)}
            transform="rotate(-90 15 15)" style={{ transition: 'stroke-dashoffset 1s linear' }} />
        </svg>
        {fmtTime(remaining)}
      </button>
      {open && (
        <div style={{
          position: 'absolute', top: 50, left: 0, zIndex: 30, display: 'flex', gap: 6,
          background: 'var(--surface)', padding: 6, borderRadius: 'var(--r-md)',
          boxShadow: 'var(--shadow-lg)', border: '1px solid var(--hairline)',
        }}>
          {[['-15', () => onAdd(-15)], ['+15', () => onAdd(15)], ['Skip', () => { onSkip(); setOpen(false); }]].map(([l, f]) => (
            <button key={l} onClick={f} style={{
              border: 0, background: 'var(--surface-2)', color: 'var(--text)', cursor: 'pointer',
              fontWeight: 600, fontSize: 13, padding: '8px 12px', borderRadius: 'var(--r-xs)', whiteSpace: 'nowrap',
            }}>{l}</button>
          ))}
        </div>
      )}
    </div>
  );
}

// ---------- Numeric keypad ----------
function Keypad({ buf, onKey, onNext, onClose, field }) {
  const K = ({ children, onPress, accent }) => (
    <button onClick={onPress} style={{
      background: accent ? 'var(--accent)' : 'var(--surface-2)', color: accent ? 'var(--on-accent)' : 'var(--text)',
      border: 0, borderRadius: 'var(--r-sm)', height: 50, fontSize: 23, fontWeight: 500,
      fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', cursor: 'pointer',
      display: 'grid', placeItems: 'center', WebkitTapHighlightColor: 'transparent',
    }}>{children}</button>
  );
  return (
    <div style={{
      flexShrink: 0, zIndex: 60,
      background: 'var(--surface)',
      borderTop: '1px solid var(--hairline)', padding: '10px 10px 26px',
      boxShadow: '0 -12px 44px rgba(0,0,0,0.4)',
      animation: 'pqUp .22s cubic-bezier(.2,.8,.2,1)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '2px 6px 10px' }}>
        <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', textTransform: 'uppercase', letterSpacing: '.06em' }}>
          {field === 'w' ? 'Weight · lb' : 'Reps'}
        </span>
        <button onClick={onClose} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 30, height: 30, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
          <Icon name="x" size={15} color="var(--text-2)" sw={2.4} />
        </button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 7 }}>
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(n => <K key={n} onPress={() => onKey(n)}>{n}</K>)}
        <K onPress={() => onKey('.')}>.</K>
        <K onPress={() => onKey('0')}>0</K>
        <K onPress={() => onKey('back')}><Icon name="chevL" size={20} sw={2.4} /></K>
      </div>
      <button onClick={onNext} style={{
        marginTop: 7, width: '100%', height: 48, border: 0, borderRadius: 'var(--r-sm)',
        background: 'var(--accent)', color: 'var(--on-accent)', fontWeight: 700, fontSize: 16, cursor: 'pointer',
        fontFamily: 'var(--font)',
      }}>Next</button>
    </div>
  );
}

// ---------- A single editable set row ----------
function SetRow({ s, idx, active, editBuf, onFocus, onToggle }) {
  const cell = (field, value) => {
    const isActive = active && active.field === field;
    const display = isActive ? (editBuf === '' ? '' : editBuf) : (value === '' || value == null ? '' : value);
    return (
      <button onClick={() => onFocus(field)} style={{
        background: isActive ? 'transparent' : (s.done ? 'transparent' : 'var(--surface-2)'),
        border: isActive ? '1.5px solid var(--accent)' : '1.5px solid transparent',
        borderRadius: 'var(--r-xs)', padding: '8px 0', textAlign: 'center', cursor: 'pointer',
        fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 600, fontSize: 16,
        color: 'var(--text)', width: '100%', WebkitTapHighlightColor: 'transparent', position: 'relative',
      }}>
        {display}
        {isActive && <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--accent)', verticalAlign: 'middle', marginLeft: 1, animation: 'pqBlink 1s steps(1) infinite' }} />}
      </button>
    );
  };
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '30px 1fr 62px 54px 38px', alignItems: 'center', gap: 7,
      padding: '0 16px', height: 52,
      background: s.done ? 'color-mix(in srgb, var(--accent) 8%, transparent)' : 'transparent',
      transition: 'background .2s ease',
    }}>
      <SetTypeBadge type={s.type} />
      <span style={{ color: 'var(--text-3)', fontSize: 15, fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', display: 'flex', alignItems: 'center', gap: 6 }}>
        {s.prev ? `${s.prev.w} × ${s.prev.r}` : '—'}
        {s.pr && <Icon name="flame" size={13} color="var(--pr)" fill />}
      </span>
      {cell('w', s.w)}
      {cell('r', s.r)}
      <button onClick={onToggle} style={{
        width: 30, height: 30, borderRadius: 'var(--r-xs)', border: 0, cursor: 'pointer',
        background: s.done ? 'var(--accent)' : 'var(--surface-2)', display: 'grid', placeItems: 'center',
        marginLeft: 'auto', WebkitTapHighlightColor: 'transparent', transition: 'background .15s ease',
      }}>
        <Icon name="check" size={16} color={s.done ? 'var(--on-accent)' : 'var(--text-3)'} sw={2.6} />
      </button>
    </div>
  );
}

// ---------- Exercise block ----------
function ExerciseBlock({ ex, exIdx, active, editBuf, onFocus, onToggle, onAddSet }) {
  return (
    <div style={{ marginTop: 6 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px 6px' }}>
        <span style={{ color: 'var(--accent)', fontWeight: 700, fontSize: 17 }}>{ex.name}</span>
        <div style={{ display: 'flex', gap: 8 }}>
          <Icon name="link" size={20} color="var(--accent)" />
          <Icon name="ellipsis" size={20} color="var(--accent)" sw={2.6} />
        </div>
      </div>
      {ex.note && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '4px 16px 8px', padding: '8px 12px', background: 'var(--pr-soft)', borderRadius: 'var(--r-xs)' }}>
          <Icon name="flag" size={14} color="var(--pr)" />
          <span style={{ color: 'var(--pr)', fontSize: 13, fontWeight: 600 }}>{ex.note}</span>
        </div>
      )}
      {ex.cue && (
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, margin: '4px 16px 8px', padding: '9px 12px', background: 'var(--accent-soft)', borderRadius: 'var(--r-xs)' }}>
          <Icon name="spark" size={14} color="var(--accent)" fill style={{ flexShrink: 0, marginTop: 1 }} />
          <span style={{ color: 'var(--accent)', fontSize: 13, fontWeight: 600, lineHeight: 1.4 }}>{ex.cue}</span>
        </div>
      )}
      <div style={{ display: 'grid', gridTemplateColumns: '30px 1fr 62px 54px 38px', gap: 7, padding: '0 16px', height: 30, alignItems: 'center', fontSize: 11, letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--text-3)', fontWeight: 600 }}>
        <span>Set</span><span>Previous</span><span style={{ textAlign: 'center' }}>lb</span><span style={{ textAlign: 'center' }}>Reps</span><span></span>
      </div>
      {ex.sets.map((s, i) => (
        <SetRow key={i} s={s} idx={i}
          active={active && active.exIdx === exIdx && active.setIdx === i ? active : null}
          editBuf={editBuf} onFocus={(f) => onFocus(exIdx, i, f)} onToggle={() => onToggle(exIdx, i)} />
      ))}
      <button onClick={() => onAddSet(exIdx)} style={{
        margin: '8px 16px 0', width: 'calc(100% - 32px)', border: 0, cursor: 'pointer',
        background: 'var(--surface-2)', color: 'var(--text-2)', fontWeight: 600, fontSize: 14,
        padding: '11px 0', borderRadius: 'var(--r-sm)', fontFamily: 'var(--font)',
      }}>+ Add set</button>
    </div>
  );
}

// ---------- Active Workout screen ----------
function ActiveWorkout({ plan, title, coached, onFinish, onCancel, onToast }) {
  const [exercises, setExercises] = useState(() => JSON.parse(JSON.stringify(plan || PQ.activeWorkout.exercises)));
  const wkName = title || PQ.activeWorkout.name;
  const [active, setActive] = useState(null);   // { exIdx, setIdx, field }
  const [editBuf, setEditBuf] = useState('');
  const [fresh, setFresh] = useState(true);
  const [resting, setResting] = useState(false);
  const [restKey, setRestKey] = useState(0);
  const startRef = useRef(Date.now());
  const scrollRef = useRef(null);
  const startRest = () => { setResting(true); setRestKey(k => k + 1); };

  const commit = (exIdx, setIdx, field, val) => {
    setExercises(prev => prev.map((ex, ei) => ei !== exIdx ? ex : {
      ...ex, sets: ex.sets.map((s, si) => si !== setIdx ? s : { ...s, [field]: val === '' ? '' : Number(val) }),
    }));
  };

  const focusCell = (exIdx, setIdx, field) => {
    if (active) commit(active.exIdx, active.setIdx, active.field, editBuf);
    const cur = exercises[exIdx].sets[setIdx][field];
    setActive({ exIdx, setIdx, field });
    setEditBuf(cur === '' || cur == null ? '' : String(cur));
    setFresh(true);
  };

  const onKey = (k) => {
    setEditBuf(b => {
      if (k === 'back') return b.slice(0, -1);
      if (k === '.') return b.includes('.') ? b : (b === '' ? '0.' : b + '.');
      if (fresh) { setFresh(false); return k; }
      return (b + k).slice(0, 6);
    });
    setFresh(false);
  };

  const onNext = () => {
    if (!active) return;
    commit(active.exIdx, active.setIdx, active.field, editBuf);
    // move w -> r -> next set's w
    if (active.field === 'w') { focusCell(active.exIdx, active.setIdx, 'r'); return; }
    const ex = exercises[active.exIdx];
    if (active.setIdx + 1 < ex.sets.length) { focusCell(active.exIdx, active.setIdx + 1, 'w'); }
    else { commit(active.exIdx, active.setIdx, active.field, editBuf); setActive(null); }
  };

  const closeKeypad = () => { if (active) commit(active.exIdx, active.setIdx, active.field, editBuf); setActive(null); };

  const toggle = (exIdx, setIdx) => {
    if (active) { commit(active.exIdx, active.setIdx, active.field, editBuf); setActive(null); }
    setExercises(prev => prev.map((ex, ei) => ei !== exIdx ? ex : {
      ...ex, sets: ex.sets.map((s, si) => {
        if (si !== setIdx) return s;
        const nowDone = !s.done;
        const isPr = nowDone && s.prev && Number(s.w) > s.prev.w;
        return { ...s, done: nowDone, pr: isPr };
      }),
    }));
    const s = exercises[exIdx].sets[setIdx];
    if (!s.done) {
      startRest();
      if (s.prev && Number(s.w) > s.prev.w) onToast('🏆  New weight PR on ' + exercises[exIdx].name);
    }
  };

  const addSet = (exIdx) => {
    setExercises(prev => prev.map((ex, ei) => {
      if (ei !== exIdx) return ex;
      const last = ex.sets[ex.sets.length - 1];
      const nums = ex.sets.filter(s => s.type !== 'W').length;
      return { ...ex, sets: [...ex.sets, { type: nums + 1, prev: last ? last.prev : null, w: last ? last.w : '', r: last ? last.r : '', done: false }] };
    }));
  };

  const doneCount = exercises.reduce((a, ex) => a + ex.sets.filter(s => s.done).length, 0);
  const totalCount = exercises.reduce((a, ex) => a + ex.sets.length, 0);
  const volume = exercises.reduce((a, ex) => a + ex.sets.filter(s => s.done).reduce((b, s) => b + (Number(s.w) || 0) * (Number(s.r) || 0), 0), 0);

  return (
    <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)', display: 'flex', flexDirection: 'column' }}>
      {/* sticky header */}
      <div style={{
        paddingTop: SAFE_TOP, position: 'sticky', top: 0, zIndex: 25,
        background: 'color-mix(in srgb, var(--bg) 82%, transparent)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid var(--hairline)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 16px 12px', minHeight: 48 }}>
          <div style={{ minWidth: 100 }}>
            {resting
              ? <RestPill key={restKey} total={90} onDone={() => setResting(false)} />
              : <button onClick={startRest} style={{ display: 'flex', alignItems: 'center', gap: 7, border: 0, background: 'var(--surface-2)', color: 'var(--text)', padding: '9px 13px', borderRadius: 'var(--r-full)', cursor: 'pointer', fontWeight: 600, fontSize: 14 }}>
                  <Icon name="timer" size={17} color="var(--text-2)" /> Rest
                </button>}
          </div>
          <Btn variant="success" full={false} size="sm" style={{ padding: '9px 22px', borderRadius: 'var(--r-full)', fontSize: 15 }} onClick={() => onFinish({ volume, sets: doneCount, dur: fmtTime(742 + Math.floor((Date.now() - startRef.current) / 1000)) })}>Finish</Btn>
        </div>
      </div>

      {/* scroll body */}
      <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', paddingBottom: 40 }}>
        <div style={{ padding: '18px 16px 6px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
            <h1 style={{ margin: 0, fontSize: 27, fontWeight: 700, letterSpacing: '-.02em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{wkName}</h1>
            <Icon name="ellipsis" size={20} color="var(--text-3)" sw={2.6} style={{ flexShrink: 0 }} />
          </div>
          {coached && (
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 8, background: 'var(--accent-soft)', color: 'var(--accent)', padding: '5px 11px', borderRadius: 'var(--r-full)', fontSize: 12.5, fontWeight: 700 }}>
              <Icon name="spark" size={13} color="var(--accent)" fill /> Coached by Physique
            </div>
          )}
          <Elapsed base={742} startRef={startRef} />
          {/* live stats strip */}
          <div style={{ display: 'flex', gap: 18, marginTop: 12 }}>
            {[['Volume', (volume / 1000).toFixed(1) + 'k'], ['Sets', `${doneCount}/${totalCount}`], ['PRs', exercises.flat ? exercises.reduce((a, ex) => a + ex.sets.filter(s => s.pr).length, 0) : 0]].map(([l, v]) => (
              <div key={l}>
                <div style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.05em' }}>{l}</div>
                <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 19, fontWeight: 700, marginTop: 2 }}>{v}</div>
              </div>
            ))}
          </div>
          <input placeholder="Add notes…" style={{ marginTop: 14, width: '100%', border: 0, background: 'transparent', color: 'var(--text)', fontSize: 15, fontFamily: 'var(--font)', outline: 'none', padding: '4px 0', borderBottom: '1px solid var(--hairline)' }} />
        </div>

        {exercises.map((ex, i) => (
          <ExerciseBlock key={i} ex={ex} exIdx={i} active={active} editBuf={editBuf}
            onFocus={focusCell} onToggle={toggle} onAddSet={addSet} />
        ))}

        <div style={{ padding: '20px 16px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn variant="secondary" onClick={() => onToast('Exercise picker — add movements')}>+ Add exercises</Btn>
          <Btn variant="destructive" onClick={onCancel}>Cancel workout</Btn>
        </div>
      </div>

      {active && <Keypad buf={editBuf} field={active.field} onKey={onKey} onNext={onNext} onClose={closeKeypad} />}
    </div>
  );
}

window.ActiveWorkout = ActiveWorkout;
window.fmtTime = fmtTime;
window.SAFE_TOP = SAFE_TOP;
