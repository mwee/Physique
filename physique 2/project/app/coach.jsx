/* PHYSIQUE — AI Coach mode: mode toggle, coach home, ask-the-coach */
const { useState: useStateC } = React;

// ---------- Templates / AI Coach segmented toggle ----------
function ModeToggle({ mode, onMode }) {
  const opts = [['template', 'Templates', null], ['coach', 'AI Coach', 'spark']];
  return (
    <div style={{ display: 'flex', background: 'var(--surface-2)', borderRadius: 'var(--r-full)', padding: 4, border: '1px solid var(--hairline)', gap: 4 }}>
      {opts.map(([id, label, ic]) => {
        const a = mode === id;
        return (
          <button key={id} onClick={() => onMode(id)} style={{
            flex: 1, border: 0, cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '9px 0',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            fontFamily: 'var(--font)', fontWeight: 600, fontSize: 14,
            background: a ? 'var(--accent)' : 'transparent', color: a ? 'var(--on-accent)' : 'var(--text-2)',
            boxShadow: a ? '0 4px 14px var(--accent-soft)' : 'none', transition: 'all .18s ease',
            WebkitTapHighlightColor: 'transparent',
          }}>
            {ic && <Icon name={ic} size={15} color={a ? 'var(--on-accent)' : 'var(--text-2)'} fill={a} />}
            {label}
          </button>
        );
      })}
    </div>
  );
}

// ---------- One coach exercise with expandable "why" ----------
function CoachExercise({ ex, i }) {
  const [open, setOpen] = useStateC(false);
  const repLabel = ex.unit === 's' ? `${ex.reps}s` : `× ${ex.reps}`;
  return (
    <div style={{ borderTop: i ? '1px solid var(--hairline)' : 0, padding: '14px 16px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 30, height: 30, borderRadius: 'var(--r-xs)', background: 'var(--surface-2)', display: 'grid', placeItems: 'center', flexShrink: 0, fontFamily: 'var(--font-num)', fontWeight: 700, fontSize: 14, color: 'var(--text-2)' }}>{i + 1}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 600, fontSize: 15 }}>{ex.name}</div>
        </div>
        <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 14, color: 'var(--text)' }}>{ex.sets} <span style={{ color: 'var(--text-3)', fontWeight: 600 }}>{repLabel}</span></span>
      </div>
      {/* coach cue */}
      <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start', marginTop: 10, marginLeft: 42 }}>
        <Icon name="spark" size={14} color="var(--accent)" fill style={{ flexShrink: 0, marginTop: 1 }} />
        <span style={{ color: 'var(--text-2)', fontSize: 13, lineHeight: 1.45 }}>{ex.cue}</span>
      </div>
      <button onClick={() => setOpen(o => !o)} style={{ marginLeft: 42, marginTop: 8, border: 0, background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5, color: 'var(--accent)', fontWeight: 600, fontSize: 12.5, padding: 0, fontFamily: 'var(--font)' }}>
        <Icon name="info" size={13} color="var(--accent)" /> Why this?
        <Icon name="chevD" size={13} color="var(--accent)" style={{ transform: open ? 'rotate(180deg)' : 'none', transition: 'transform .2s ease' }} />
      </button>
      {open && (
        <div style={{ marginLeft: 42, marginTop: 8, padding: '10px 12px', background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', color: 'var(--text-2)', fontSize: 13, lineHeight: 1.5, animation: 'pqUp .2s ease' }}>{ex.why}</div>
      )}
    </div>
  );
}

// ---------- Ask the coach (scripted chips + live free-text) ----------
function AskCoach() {
  const [thread, setThread] = useStateC([]);
  const [input, setInput] = useStateC('');
  const [loading, setLoading] = useStateC(false);
  const used = thread.filter(m => m.role === 'user').map(m => m.content);
  const remainingFaqs = PQ.coach.faqs.filter(f => !used.includes(f.q));

  const pushMsg = (m) => setThread(t => [...t, m]);

  const askFaq = (f) => { pushMsg({ role: 'user', content: f.q }); setTimeout(() => pushMsg({ role: 'coach', content: f.a }), 260); };

  const askFree = async () => {
    const q = input.trim(); if (!q || loading) return;
    setInput(''); pushMsg({ role: 'user', content: q }); setLoading(true);
    let answer = null;
    try {
      if (window.claude && window.claude.complete) {
        answer = await window.claude.complete({
          messages: [{ role: 'user', content: `You are a warm, concise strength coach inside a workout app called Physique, talking to a nervous beginner. Reply in 2-3 short plain-language sentences, encouraging, no markdown, no lists. Question: ${q}` }],
        });
      }
    } catch (e) { answer = null; }
    if (!answer) answer = "Great question. As a beginner, focus on consistent form and showing up 3 days a week — the weight will take care of itself. Tap any exercise's \u00b7\u00b7\u00b7 menu and I can swap or explain a move anytime.";
    pushMsg({ role: 'coach', content: String(answer).trim() }); setLoading(false);
  };

  return (
    <div>
      {thread.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 12 }}>
          {thread.map((m, i) => m.role === 'user' ? (
            <div key={i} style={{ alignSelf: 'flex-end', maxWidth: '82%', background: 'var(--accent)', color: 'var(--on-accent)', padding: '9px 13px', borderRadius: '14px 14px 4px 14px', fontSize: 13.5, lineHeight: 1.4, fontWeight: 500 }}>{m.content}</div>
          ) : (
            <div key={i} style={{ alignSelf: 'flex-start', maxWidth: '88%', display: 'flex', gap: 8 }}>
              <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', flexShrink: 0 }}><Icon name="spark" size={14} color="var(--accent)" fill /></div>
              <div style={{ background: 'var(--surface-2)', color: 'var(--text)', padding: '9px 13px', borderRadius: '14px 14px 14px 4px', fontSize: 13.5, lineHeight: 1.45 }}>{m.content}</div>
            </div>
          ))}
          {loading && (
            <div style={{ alignSelf: 'flex-start', display: 'flex', gap: 8, alignItems: 'center' }}>
              <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center' }}><Icon name="spark" size={14} color="var(--accent)" fill /></div>
              <div style={{ background: 'var(--surface-2)', padding: '11px 14px', borderRadius: 14, display: 'flex', gap: 4 }}>
                {[0, 1, 2].map(n => <span key={n} style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--text-3)', animation: `pqBlink 1s ${n * 0.2}s infinite` }} />)}
              </div>
            </div>
          )}
        </div>
      )}

      {remainingFaqs.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
          {remainingFaqs.map((f, i) => (
            <button key={i} onClick={() => askFaq(f)} style={{ border: '1px solid var(--hairline)', background: 'var(--surface)', color: 'var(--text)', cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '8px 13px', fontSize: 13, fontWeight: 500, fontFamily: 'var(--font)' }}>{f.q}</button>
          ))}
        </div>
      )}

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', padding: '5px 5px 5px 15px', border: '1px solid var(--hairline)' }}>
        <input value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => { if (e.key === 'Enter') askFree(); }} placeholder="Ask your coach anything\u2026" style={{ flex: 1, border: 0, background: 'transparent', color: 'var(--text)', fontSize: 14.5, outline: 'none', fontFamily: 'var(--font)' }} />
        <button onClick={askFree} disabled={loading} style={{ border: 0, background: 'var(--accent)', borderRadius: '50%', width: 36, height: 36, display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0, opacity: loading ? 0.5 : 1 }}>
          <Icon name="send" size={17} color="var(--on-accent)" fill />
        </button>
      </div>
    </div>
  );
}

// ---------- Build an ActiveWorkout plan from the coach session ----------
function coachPlan() {
  return PQ.coach.session.exercises.map(ex => ({
    name: ex.name, note: null, cue: ex.cue,
    sets: Array.from({ length: ex.sets }, (_, i) => ({
      type: i + 1, prev: null,
      w: ex.target == null ? '' : ex.target,
      r: ex.reps, done: false, unit: ex.unit,
    })),
  }));
}

// ---------- AI Coach body (no Screen wrapper) ----------
function CoachBody({ onStart }) {
  const [goal, setGoal] = useStateC(PQ.coach.goal);
  const [level, setLevel] = useStateC(PQ.coach.level);
  const [mins, setMins] = useStateC(PQ.coach.minutes);
  const cycle = (cur, arr, set) => set(arr[(arr.indexOf(cur) + 1) % arr.length]);
  const s = PQ.coach.session;
  const totalSets = s.exercises.reduce((a, e) => a + e.sets, 0);

  const chip = (label, value, onClick) => (
    <button onClick={onClick} style={{ flex: 1, border: '1px solid var(--hairline)', background: 'var(--surface)', cursor: 'pointer', borderRadius: 'var(--r-sm)', padding: '10px 12px', textAlign: 'left', fontFamily: 'var(--font)' }}>
      <div style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 3 }}>
        <span style={{ fontWeight: 600, fontSize: 14 }}>{value}</span>
        <Icon name="chevD" size={14} color="var(--text-3)" />
      </div>
    </button>
  );

  return (
    <div>
      {/* coach rationale */}
      <div style={{ marginTop: 16, background: 'var(--accent-tint)', borderRadius: 'var(--r-lg)', padding: 'var(--s5)', border: '1px solid var(--accent-soft)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--accent)', display: 'grid', placeItems: 'center', boxShadow: '0 4px 14px var(--accent-soft)' }}>
            <Icon name="spark" size={18} color="var(--on-accent)" fill />
          </div>
          <div style={{ fontWeight: 700, fontSize: 15 }}>Your coach planned this</div>
        </div>
        <p style={{ margin: '12px 0 0', color: 'var(--text)', fontSize: 14, lineHeight: 1.5, opacity: 0.92 }}>{PQ.coach.rationale}</p>
      </div>

      {/* controls */}
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        {chip('Goal', goal, () => cycle(goal, ['Build muscle', 'Get stronger', 'Lose fat'], setGoal))}
        {chip('Level', level, () => cycle(level, ['Beginner', 'Returning', 'Intermediate'], setLevel))}
        {chip('Time', mins + ' min', () => cycle(mins, [30, 45, 60], setMins))}
      </div>

      {/* generated session */}
      <SectionLabel style={{ marginTop: 22 }}>Generated session</SectionLabel>
      <Card pad="0">
        <div style={{ padding: '16px 16px 14px', borderBottom: '1px solid var(--hairline)' }}>
          <div style={{ fontWeight: 700, fontSize: 17 }}>{s.name}</div>
          <div style={{ color: 'var(--text-3)', fontSize: 13, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{s.exercises.length} exercises · {totalSets} sets · ~{mins} min</div>
        </div>
        {s.exercises.map((ex, i) => <CoachExercise key={i} ex={ex} i={i} />)}
      </Card>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 14 }}>
        <Btn onClick={() => onStart(coachPlan(), s.name)}><Icon name="play" size={16} color="var(--on-accent)" fill /> Start coached workout</Btn>
      </div>

      {/* ask coach */}
      <SectionLabel style={{ marginTop: 26 }}>Ask your coach</SectionLabel>
      <AskCoach />
    </div>
  );
}

// ---------- Your routines (custom folders) ----------
function RoutinesSection({ onStart, onToast }) {
  return (
    <div style={{ marginTop: 28 }}>
      <SectionLabel>Your routines</SectionLabel>
      <button onClick={() => onToast && onToast('New routine — build your own')} style={{ width: '100%', border: '1px dashed var(--hairline-strong)', background: 'transparent', color: 'var(--text-2)', cursor: 'pointer', borderRadius: 'var(--r-md)', padding: '13px 0', fontWeight: 600, fontSize: 14, fontFamily: 'var(--font)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7, marginBottom: 18 }}>
        <Icon name="plus" size={17} color="var(--text-2)" sw={2.2} /> New routine
      </button>
      {PQ.folders.map(f => (
        <div key={f.id} style={{ marginBottom: 22 }}>
          <SectionLabel>{f.name}</SectionLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {f.routines.map(r => (
              <Card key={r.id} pad="var(--s5)">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 700, fontSize: 17 }}>{r.name}</div>
                    <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 4, lineHeight: 1.4 }}>{r.exercises.join(' · ')}</div>
                    <div style={{ color: 'var(--text-3)', fontSize: 12, marginTop: 8, fontWeight: 600 }}>{r.count} exercises · Last {r.last}</div>
                  </div>
                  <Icon name="ellipsis" size={20} color="var(--text-3)" sw={2.6} />
                </div>
                <div style={{ marginTop: 14 }}>
                  <Btn variant="secondary" size="sm" onClick={onStart}><Icon name="play" size={14} color="var(--accent)" fill /> Start workout</Btn>
                </div>
              </Card>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------- One scheduled, startable session ----------
function SessionCard({ d, onStart }) {
  return (
    <Card pad="var(--s5)">
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontWeight: 700, fontSize: 17 }}>{d.name}</span>
        {d.sub && <Pill tone="neutral">{d.sub}</Pill>}
      </div>
      <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 4, lineHeight: 1.4 }}>{d.lifts.join(' · ')}</div>
      <div style={{ display: 'flex', gap: 10, marginTop: 10, color: 'var(--text-3)', fontSize: 12, fontWeight: 600, fontVariantNumeric: 'tabular-nums', flexWrap: 'wrap' }}>
        <span>Top set <span style={{ color: 'var(--accent)' }}>{window.tplFmt(d.top.w)} lb × {d.top.r}{d.top.amrap ? '+' : ''}</span></span>
        <span>·</span><span>{d.setCount} sets</span><span>·</span><span>~{d.est} min</span>
      </div>
      <div style={{ marginTop: 14 }}>
        <Btn variant="secondary" size="sm" onClick={onStart}><Icon name="play" size={14} color="var(--accent)" fill /> Start workout</Btn>
      </div>
    </Card>
  );
}

// ---------- Templates body — active program schedule + library CTA ----------
function TemplatesBody({ empty, activeProgram, onBrowse, onStartSession, onWeek, onAdjust, onStartRoutine, onCoach, onToast }) {
  const prog = activeProgram ? TPL.programs.find(p => p.id === activeProgram.programId) : null;

  if (empty || !prog) {
    return (
      <div style={{ marginTop: 16 }}>
        <div style={{ borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', boxShadow: 'var(--shadow)', background: 'var(--surface)', padding: 'var(--s6)', textAlign: 'center' }}>
          <div style={{ width: 52, height: 52, borderRadius: 'var(--r-md)', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', margin: '0 auto' }}>
            <Icon name="clipboard" size={26} color="var(--accent)" />
          </div>
          <div style={{ fontWeight: 700, fontSize: 20, marginTop: 16, letterSpacing: '-.01em' }}>Start with a proven program</div>
          <div style={{ color: 'var(--text-2)', fontSize: 14, lineHeight: 1.5, marginTop: 8 }}>Pick a template like 5/3/1 or GZCLP, enter your 1RM, and Physique schedules every workout for you.</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 20 }}>
            <Btn onClick={onBrowse}><Icon name="list" size={16} color="var(--on-accent)" /> Browse template library</Btn>
            <Btn variant="ghost" onClick={onCoach}><Icon name="spark" size={16} color="var(--text)" fill /> Or let your AI coach build one</Btn>
          </div>
        </div>
        {!empty && <RoutinesSection onStart={onStartRoutine} onToast={onToast} />}
      </div>
    );
  }

  const days = window.tplScheduleDays(activeProgram);
  const week = activeProgram.week || 0;
  const waved = prog.waved && prog.cycleWeeks > 1;
  const weekName = prog.weekNames ? prog.weekNames[week] : null;

  return (
    <div style={{ marginTop: 16 }}>
      {/* active program header */}
      <div style={{ display: 'flex', gap: 14, alignItems: 'center', background: 'var(--surface)', borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', boxShadow: 'var(--shadow)', padding: 'var(--s5)' }}>
        <ProgramGlyph text={prog.glyph} size={46} active />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, color: 'var(--accent)', fontWeight: 700, fontSize: 11.5, textTransform: 'uppercase', letterSpacing: '.07em' }}>
            <Icon name="bolt" size={13} color="var(--accent)" fill /> Active program
          </div>
          <div style={{ fontWeight: 700, fontSize: 18, marginTop: 3 }}>{prog.name}</div>
          <div style={{ color: 'var(--text-3)', fontSize: 12.5, fontWeight: 600, marginTop: 2 }}>{prog.days} · {prog.cycle}</div>
        </div>
        <button onClick={onAdjust} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-xs)', width: 36, height: 36, display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
          <Icon name="settings" size={18} color="var(--text-2)" />
        </button>
      </div>

      {/* week control / schedule label */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 22, marginBottom: 10, padding: '0 4px' }}>
        <span style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.08em', color: 'var(--text-3)' }}>{waved ? (weekName || `Week ${week + 1}`) : 'Your split'}</span>
        {waved && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <button onClick={() => onWeek(-1)} disabled={week <= 0} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-xs)', width: 30, height: 30, display: 'grid', placeItems: 'center', cursor: week <= 0 ? 'default' : 'pointer', opacity: week <= 0 ? 0.4 : 1 }}><Icon name="chevL" size={16} color="var(--text)" sw={2.4} /></button>
            <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-2)', fontVariantNumeric: 'tabular-nums', minWidth: 64, textAlign: 'center' }}>Week {week + 1} / {prog.cycleWeeks}</span>
            <button onClick={() => onWeek(1)} disabled={week >= prog.cycleWeeks - 1} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-xs)', width: 30, height: 30, display: 'grid', placeItems: 'center', cursor: week >= prog.cycleWeeks - 1 ? 'default' : 'pointer', opacity: week >= prog.cycleWeeks - 1 ? 0.4 : 1 }}><Icon name="chevR" size={16} color="var(--text)" sw={2.4} /></button>
          </div>
        )}
      </div>

      {/* scheduled sessions */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {days.map(d => <SessionCard key={d.index} d={d} onStart={() => onStartSession(d.index)} />)}
      </div>

      {/* browse library CTA */}
      <button onClick={onBrowse} style={{ marginTop: 16, width: '100%', border: '1px dashed var(--hairline-strong)', background: 'transparent', color: 'var(--accent)', cursor: 'pointer', borderRadius: 'var(--r-md)', padding: '13px 0', fontWeight: 700, fontSize: 14, fontFamily: 'var(--font)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
        <Icon name="list" size={17} color="var(--accent)" /> Browse template library
      </button>

      <RoutinesSection onStart={onStartRoutine} onToast={onToast} />
    </div>
  );
}

// ---------- Plan tab — hosts the Templates / AI Coach toggle ----------
function PlanScreen({ empty, mode, onMode, activeProgram, onBrowse, onStartSession, onWeek, onAdjust, onStartRoutine, onStartCoached, onToast }) {
  return (
    <Screen>
      <ScreenHeader sub={mode === 'coach' ? 'AI Coach' : 'Your program'} title="Plan" />
      <div style={{ padding: '14px 16px 0' }}>
        <ModeToggle mode={mode} onMode={onMode} />
        {mode === 'coach'
          ? <CoachBody onStart={onStartCoached} />
          : <TemplatesBody empty={empty} activeProgram={activeProgram} onBrowse={onBrowse} onStartSession={onStartSession} onWeek={onWeek} onAdjust={onAdjust} onStartRoutine={onStartRoutine} onCoach={() => onMode('coach')} onToast={onToast} />}
      </div>
    </Screen>
  );
}

Object.assign(window, { ModeToggle, CoachBody, TemplatesBody, PlanScreen, SessionCard, RoutinesSection, AskCoach, coachPlan });
