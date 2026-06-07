/* PHYSIQUE — tab screens + scaffolding (Home, History, Exercises, Progress, TabBar) */

function Screen({ children, scrollRef }) {
  return (
    <div ref={scrollRef} style={{
      position: 'absolute', inset: 0, overflowY: 'auto', WebkitOverflowScrolling: 'touch',
      paddingTop: SAFE_TOP, paddingBottom: 108,
    }}>{children}</div>
  );
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

function SectionLabel({ children, style }) {
  return <div style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.08em', color: 'var(--text-3)', padding: '0 4px 10px', ...style }}>{children}</div>;
}

// ---------- Empty state ----------
function EmptyState({ icon, title, body, cta, onCta, secondary, onSecondary, compact }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: compact ? '36px 24px' : '52px 28px' }}>
      <div style={{ width: 64, height: 64, borderRadius: 'var(--r-lg)', background: 'var(--surface)', border: '1px solid var(--hairline)', display: 'grid', placeItems: 'center' }}>
        <Icon name={icon} size={28} color="var(--text-3)" />
      </div>
      <div style={{ fontWeight: 700, fontSize: 18, marginTop: 18 }}>{title}</div>
      <div style={{ color: 'var(--text-2)', fontSize: 14, lineHeight: 1.5, marginTop: 8, maxWidth: 280 }}>{body}</div>
      {cta && (
        <div style={{ width: '100%', maxWidth: 280, marginTop: 22, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Btn onClick={onCta}>{cta}</Btn>
          {secondary && <Btn variant="ghost" onClick={onSecondary}>{secondary}</Btn>}
        </div>
      )}
    </div>
  );
}

function StatTile({ label, value, unit, accent, icon }) {
  return (
    <div style={{ flex: 1, background: 'var(--surface)', borderRadius: 'var(--r-md)', padding: '14px 14px', border: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text-3)', fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em' }}>
        {icon && <Icon name={icon} size={13} color="var(--text-3)" />} {label}
      </div>
      <div style={{ marginTop: 8, fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 26, letterSpacing: '-.02em', color: accent ? 'var(--accent)' : 'var(--text)' }}>
        {value}{unit && <span style={{ fontSize: 14, color: 'var(--text-3)', fontWeight: 600 }}> {unit}</span>}
      </div>
    </div>
  );
}

// ---------- TabBar ----------
function TabBar({ tab, onTab }) {
  const tabs = [['home', 'Home', 'home'], ['plan', 'Plan', 'clipboard'], ['history', 'History', 'calendar'], ['exercises', 'Exercises', 'dumbbell'], ['progress', 'Progress', 'progress']];
  return (
    <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 20, paddingBottom: 22, paddingTop: 8,
      background: 'color-mix(in srgb, var(--bg) 82%, transparent)', backdropFilter: 'blur(20px) saturate(160%)', WebkitBackdropFilter: 'blur(20px) saturate(160%)',
      borderTop: '1px solid var(--hairline)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-around', alignItems: 'center' }}>
        {tabs.map(([id, label, icon]) => {
          const a = tab === id;
          return (
            <button key={id} onClick={() => onTab(id)} style={{ border: 0, background: 'transparent', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '2px 10px', WebkitTapHighlightColor: 'transparent' }}>
              <Icon name={icon} size={23} color={a ? 'var(--accent)' : 'var(--text-3)'} sw={a ? 2.1 : 1.8} />
              <span style={{ fontSize: 10, fontWeight: 600, color: a ? 'var(--accent)' : 'var(--text-3)' }}>{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ---------- Home ----------
function HomeScreen({ empty, onStart, onRoutines, onSession, onProgress, onPaywall, onCoach }) {
  const next = PQ.folders[0].routines[1]; // Pull Day
  const wkdate = PQ.today.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' });

  if (empty) {
    return (
      <Screen>
        <ScreenHeader sub={wkdate} title="Welcome" action={
          <button onClick={onProgress} style={{ border: '1px solid var(--hairline)', background: 'var(--surface)', borderRadius: 'var(--r-full)', width: 40, height: 40, cursor: 'pointer', display: 'grid', placeItems: 'center' }}>
            <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'var(--accent)', display: 'grid', placeItems: 'center', color: 'var(--on-accent)', fontWeight: 700, fontSize: 13 }}>MW</div>
          </button>} />
        <div style={{ padding: '14px 16px 0' }}>
          <div style={{ borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', boxShadow: 'var(--shadow)', background: 'var(--surface)', padding: 'var(--s6)', textAlign: 'center' }}>
            <div style={{ width: 52, height: 52, borderRadius: 'var(--r-md)', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', margin: '0 auto' }}>
              <Icon name="bolt" size={26} color="var(--accent)" fill />
            </div>
            <div style={{ fontWeight: 700, fontSize: 20, marginTop: 16, letterSpacing: '-.01em' }}>Let's log your first lift</div>
            <div style={{ color: 'var(--text-2)', fontSize: 14, lineHeight: 1.5, marginTop: 8 }}>Start a session and Physique begins tracking your strength, volume and records automatically.</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 20 }}>
              <Btn onClick={onCoach}><Icon name="spark" size={16} color="var(--on-accent)" fill /> Generate today's session</Btn>
              <Btn variant="ghost" onClick={onRoutines}><Icon name="clipboard" size={16} color="var(--text)" /> Browse templates</Btn>
            </div>
          </div>

          <SectionLabel style={{ marginTop: 24 }}>Your week</SectionLabel>
          <div style={{ display: 'flex', gap: 10 }}>
            {[['Streak', 'flame'], ['Workouts', 'dumbbell'], ['Volume', 'chart']].map(([l, ic]) => (
              <div key={l} style={{ flex: 1, background: 'var(--surface)', borderRadius: 'var(--r-md)', padding: '14px', border: '1px dashed var(--hairline-strong)', textAlign: 'center' }}>
                <Icon name={ic} size={18} color="var(--text-3)" />
                <div style={{ color: 'var(--text-3)', fontSize: 22, fontWeight: 700, marginTop: 6, fontFamily: 'var(--font-num)' }}>—</div>
                <div style={{ color: 'var(--text-3)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.05em', marginTop: 2 }}>{l}</div>
              </div>
            ))}
          </div>
          <div style={{ color: 'var(--text-3)', fontSize: 13, textAlign: 'center', marginTop: 16, lineHeight: 1.5 }}>Finish a workout to see your stats and records here.</div>
        </div>
      </Screen>
    );
  }

  return (
    <Screen>
      <ScreenHeader sub={wkdate} title="Ready to lift" action={
        <button onClick={onProgress} style={{ border: 0, background: 'var(--surface)', borderRadius: 'var(--r-full)', width: 40, height: 40, cursor: 'pointer', display: 'grid', placeItems: 'center', border: '1px solid var(--hairline)' }}>
          <div style={{ width: 26, height: 26, borderRadius: '50%', background: 'var(--accent)', display: 'grid', placeItems: 'center', color: 'var(--on-accent)', fontWeight: 700, fontSize: 13 }}>MW</div>
        </button>} />

      <div style={{ padding: '14px 16px 0' }}>
        {/* Up next hero */}
        <div style={{ borderRadius: 'var(--r-lg)', overflow: 'hidden', border: '1px solid var(--hairline)', boxShadow: 'var(--shadow)' }}>
          <div style={{ background: 'var(--surface)', padding: 'var(--s5)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, color: 'var(--accent)', fontWeight: 700, fontSize: 12, textTransform: 'uppercase', letterSpacing: '.07em' }}>
              <Icon name="bolt" size={14} color="var(--accent)" fill /> Up next
            </div>
            <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: '-.02em', marginTop: 8 }}>{next.name}</div>
            <div style={{ color: 'var(--text-2)', fontSize: 14, marginTop: 4 }}>{next.exercises.join(' · ')}</div>
            <div style={{ display: 'flex', gap: 14, marginTop: 12, color: 'var(--text-3)', fontSize: 13, fontWeight: 600 }}>
              <span>{next.count} exercises</span><span>·</span><span>Last {next.last}</span>
            </div>
            <div style={{ marginTop: 16 }}>
              <Btn onClick={onStart}><Icon name="play" size={16} color="var(--on-accent)" fill /> Start workout</Btn>
            </div>
          </div>
        </div>

        {/* quick stats */}
        <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
          <StatTile label="Streak" value={PQ.progress.streakWeeks} unit="wk" icon="flame" accent />
          <StatTile label="This week" value={PQ.progress.workoutsThisWeek} unit="lifts" icon="dumbbell" />
          <StatTile label="Volume" value={(PQ.progress.weekVolume / 1000).toFixed(1) + 'k'} icon="chart" />
        </div>

        {/* PR nudge */}
        <div onClick={onProgress} style={{ marginTop: 16, cursor: 'pointer', display: 'flex', gap: 14, alignItems: 'center', background: 'var(--surface)', borderRadius: 'var(--r-lg)', padding: 'var(--s5)', borderLeft: '3px solid var(--pr)', border: '1px solid var(--hairline)' }}>
          <div style={{ width: 42, height: 42, borderRadius: 'var(--r-sm)', background: 'var(--pr-soft)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
            <Icon name="flame" size={22} color="var(--pr)" fill />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 700, fontSize: 15 }}>You're due for a PR</div>
            <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 2, lineHeight: 1.4 }}>{PQ.progress.nudge.ex} 1RM is trending up 3 sessions straight.</div>
          </div>
          <Icon name="chevR" size={18} color="var(--text-3)" />
        </div>

        {/* routines link */}
        <div style={{ marginTop: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <SectionLabel>Recent</SectionLabel>
            <button onClick={onRoutines} style={{ border: 0, background: 'transparent', color: 'var(--accent)', fontWeight: 600, fontSize: 13, cursor: 'pointer' }}>All routines</button>
          </div>
          <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
            {PQ.history.slice(0, 3).map((s, i) => (
              <button key={s.id} onClick={() => onSession(s)} style={{ width: '100%', border: 0, background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 12, padding: '13px 16px', borderTop: i ? '1px solid var(--hairline)' : 0, textAlign: 'left' }}>
                <div style={{ width: 34, height: 34, borderRadius: 'var(--r-xs)', background: 'var(--surface-2)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                  <Icon name="dumbbell" size={17} color="var(--text-2)" />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 15, display: 'flex', alignItems: 'center', gap: 7 }}>{s.name} {s.prs > 0 && <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> {s.prs}</Pill>}</div>
                  <div style={{ color: 'var(--text-3)', fontSize: 12, marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{relDay(s.date)} · {s.dur} · {(s.volume / 1000).toFixed(1)}k lb</div>
                </div>
                <Icon name="chevR" size={16} color="var(--text-3)" />
              </button>
            ))}
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ---------- History ----------
function relDay(date) {
  const ms = PQ.today - date; const days = Math.round(ms / 86400000);
  if (days === 0) return 'Today'; if (days === 1) return 'Yesterday';
  if (days < 7) return days + ' days ago';
  return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
}

function fullDay(date) {
  return date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
}

function HistoryScreen({ empty, onSession, onStart }) {
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  if (empty) {
    return (
      <Screen>
        <ScreenHeader title="History" />
        <EmptyState icon="calendar" title="No workouts yet"
          body="Every session you finish lands here — with duration, volume and any records you set."
          cta="Start a workout" onCta={onStart} />
      </Screen>
    );
  }
  return (
    <Screen>
      <ScreenHeader title="History" />
      <div style={{ padding: '14px 16px 0' }}>
        {/* week streak strip */}
        <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', padding: 'var(--s5)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <span style={{ fontWeight: 600, fontSize: 15 }}>This week</span>
            <span style={{ color: 'var(--text-2)', fontSize: 13, fontWeight: 600 }}>{PQ.progress.workoutsThisWeek} of 5 planned</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            {days.map((d, i) => {
              const done = PQ.progress.weekDays[i];
              return (
                <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 32, height: 32, borderRadius: '50%', background: done ? 'var(--accent)' : 'var(--surface-2)', display: 'grid', placeItems: 'center' }}>
                    {done ? <Icon name="check" size={15} color="var(--on-accent)" sw={2.6} /> : null}
                  </div>
                  <span style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 600 }}>{d}</span>
                </div>
              );
            })}
          </div>
        </div>

        <SectionLabel style={{ marginTop: 22 }}>{PQ.history.length} workouts</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {PQ.history.map(s => (
            <Card key={s.id} pad="var(--s5)" onClick={() => onSession(s)}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 17 }}>{s.name}</div>
                  <div style={{ color: 'var(--text-3)', fontSize: 13, marginTop: 2 }}>{fullDay(s.date)}</div>
                </div>
                {s.prs > 0 && <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> {s.prs} PR{s.prs > 1 ? 's' : ''}</Pill>}
              </div>
              <div style={{ display: 'flex', gap: 22, marginTop: 14 }}>
                {[['Duration', s.dur], ['Volume', (s.volume / 1000).toFixed(1) + 'k lb'], ['Sets', s.sets]].map(([l, v]) => (
                  <div key={l}>
                    <div style={{ fontSize: 11, color: 'var(--text-3)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em' }}>{l}</div>
                    <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 17, marginTop: 3 }}>{v}</div>
                  </div>
                ))}
              </div>
            </Card>
          ))}
        </div>
      </div>
    </Screen>
  );
}

// ---------- Exercises ----------
function ExercisesScreen({ onExercise }) {
  const [q, setQ] = useState('');
  const list = PQ.exercises.filter(e => e.name.toLowerCase().includes(q.toLowerCase()));
  const groups = {};
  list.forEach(e => { (groups[e.group] = groups[e.group] || []).push(e); });
  return (
    <Screen>
      <ScreenHeader title="Exercises" />
      <div style={{ padding: '12px 16px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: '10px 13px' }}>
          <Icon name="search" size={18} color="var(--text-3)" />
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search exercises" style={{ border: 0, background: 'transparent', color: 'var(--text)', fontSize: 16, outline: 'none', flex: 1, fontFamily: 'var(--font)' }} />
        </div>
        {Object.keys(groups).map(g => (
          <div key={g} style={{ marginTop: 20 }}>
            <SectionLabel>{g}</SectionLabel>
            <div style={{ background: 'var(--surface)', borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', overflow: 'hidden' }}>
              {groups[g].map((e, i) => (
                <button key={e.id} onClick={() => onExercise(e)} style={{ width: '100%', border: 0, background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 12, padding: '13px 16px', borderTop: i ? '1px solid var(--hairline)' : 0, textAlign: 'left' }}>
                  <div style={{ width: 38, height: 38, borderRadius: 'var(--r-xs)', background: 'var(--surface-2)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                    <Icon name="dumbbell" size={19} color="var(--text-2)" />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 600, fontSize: 15 }}>{e.name}</div>
                    <div style={{ color: 'var(--text-3)', fontSize: 12, marginTop: 2, textTransform: 'capitalize' }}>{e.type}{e.best1rm ? ` · e1RM ${e.best1rm} lb` : ''}</div>
                  </div>
                  <Icon name="chevR" size={16} color="var(--text-3)" />
                </button>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Screen>
  );
}

// ---------- Bodyweight (single line, opens chart modal) ----------
function BodyweightCard({ onOpen, onLog }) {
  const bw = PQ.progress.bodyweight;
  return (
    <Card pad="0">
      <button onClick={onOpen} style={{ width: '100%', border: 0, background: 'transparent', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10, padding: '15px 16px', fontFamily: 'var(--font)', textAlign: 'left', WebkitTapHighlightColor: 'transparent' }}>
        <Icon name="progress" size={18} color="var(--text-2)" />
        <span style={{ color: 'var(--text)', fontSize: 15, fontWeight: 600, whiteSpace: 'nowrap' }}>Bodyweight</span>
        <span style={{ flex: 1, minWidth: 8 }}></span>
        <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 16, fontWeight: 600, color: 'var(--text-2)', whiteSpace: 'nowrap' }}>{bw.current.toFixed(1)} {bw.unit}</span>
        <span onClick={(e) => { e.stopPropagation(); onLog && onLog(); }} style={{ flexShrink: 0, border: 0, background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', cursor: 'pointer', borderRadius: 'var(--r-xs)', width: 32, height: 32 }}>
          <Icon name="plus" size={18} color="var(--accent)" sw={2.4} />
        </span>
      </button>
    </Card>
  );
}

// ---------- Bodyweight chart modal ----------
function BodyweightModal({ onClose, onLog }) {
  const bw = PQ.progress.bodyweight;
  const data = bw.history;
  const max = Math.max(...data), min = Math.min(...data);
  const padTop = Math.ceil(max + 0.6), padBot = Math.floor(min - 0.6);
  const months = ['Apr', 'May', 'Jun'];
  return (
    <PushScreen anim="up">
      <div style={{ paddingTop: SAFE_TOP }}>
        {/* modal header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 14px 14px' }}>
          <button onClick={onClose} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', width: 36, height: 36, display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
            <Icon name="x" size={18} color="var(--text)" sw={2.4} />
          </button>
          <div style={{ fontWeight: 700, fontSize: 18 }}>Bodyweight</div>
          <button style={{ border: 0, background: 'transparent', color: 'var(--accent)', fontWeight: 600, fontSize: 16, cursor: 'pointer', fontFamily: 'var(--font)' }}>Edit</button>
        </div>

        <div style={{ padding: '0 16px' }}>
          {/* chart card */}
          <div style={{ border: '1px solid var(--hairline)', borderRadius: 'var(--r-lg)', padding: 'var(--s5)', background: 'var(--surface)' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: 17 }}>Weight</div>
                <div style={{ color: 'var(--text-3)', fontSize: 13, marginTop: 2 }}>Last 12 weeks · {bw.unit}</div>
              </div>
              <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
                <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-.01em' }}>{bw.current.toFixed(1)}</div>
                <div style={{ color: 'var(--success)', fontSize: 12.5, fontWeight: 700 }}>▲ {bw.delta} {bw.unit}</div>
              </div>
            </div>
            {/* chart with axis labels */}
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end', height: 150, fontSize: 11, color: 'var(--text-3)', fontWeight: 600, fontVariantNumeric: 'tabular-nums', paddingBottom: 18 }}>
                <span>{padTop}</span>
                <span>{padBot}</span>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ height: 132, borderLeft: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
                  <LineChart data={data} height={132} area dot />
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11, color: 'var(--text-3)', fontWeight: 600 }}>
                  {months.map(m => <span key={m}>{m}</span>)}
                </div>
              </div>
            </div>
          </div>

          {/* add measurement */}
          <div style={{ marginTop: 16 }}>
            <Btn onClick={() => onLog && onLog()}><Icon name="plus" size={16} color="var(--on-accent)" sw={2.4} /> Add measurement</Btn>
          </div>

          {/* history */}
          <SectionLabel style={{ marginTop: 26 }}>History</SectionLabel>
          <Card pad="0">
            {bw.log.map((e, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
                <span style={{ fontSize: 14.5, fontWeight: 600 }}>{e.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} · {e.time}</span>
                <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 14.5, fontWeight: 600, color: 'var(--text-2)' }}>{e.w.toFixed(1)} {bw.unit}</span>
              </div>
            ))}
          </Card>
        </div>
      </div>
    </PushScreen>
  );
}

// ---------- Progress ----------
function ProgressScreen({ empty, onExercise, onPaywall, onLog, onBodyweight, onStart }) {
  if (empty) {
    return (
      <Screen>
        <ScreenHeader title="Progress" />
        <div style={{ padding: '14px 16px 0' }}>
          <BodyweightCard onOpen={onBodyweight} onLog={onLog} />
          <div style={{ marginTop: 16, background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 'var(--r-lg)' }}>
            <EmptyState compact icon="chart" title="No training data yet"
              body="Log a few workouts and Physique charts your estimated 1RM, weekly volume and plateau signals here."
              cta="Start a workout" onCta={onStart} />
          </div>
        </div>
      </Screen>
    );
  }
  return (
    <Screen>
      <ScreenHeader title="Progress" />
      <div style={{ padding: '14px 16px 0' }}>
        {/* bodyweight */}
        <BodyweightCard onOpen={onBodyweight} onLog={onLog} />

        {/* PR nudge */}
        <div style={{ marginTop: 16, display: 'flex', gap: 14, alignItems: 'flex-start', background: 'var(--surface)', borderRadius: 'var(--r-lg)', padding: 'var(--s5)', borderLeft: '3px solid var(--pr)', border: '1px solid var(--hairline)' }}>
          <div style={{ width: 42, height: 42, borderRadius: 'var(--r-sm)', background: 'var(--pr-soft)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
            <Icon name="flame" size={22} color="var(--pr)" fill />
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 15 }}>You're due for a PR</div>
            <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 3, lineHeight: 1.45 }}>{PQ.progress.nudge.text}</div>
          </div>
        </div>

        {/* weekly volume */}
        <Card style={{ marginTop: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ fontWeight: 600, fontSize: 15 }}>Weekly volume</span>
            <Pill tone="success"><Icon name="arrowUp" size={11} color="var(--success)" sw={2.4} /> PR week pace</Pill>
          </div>
          <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 32, fontWeight: 700, letterSpacing: '-.02em', marginTop: 8 }}>
            {(PQ.progress.weekVolume / 1000).toFixed(1)}k<span style={{ fontSize: 15, color: 'var(--text-3)', fontWeight: 600 }}> lb</span>
          </div>
          <div style={{ marginTop: 14 }}><BarChart data={PQ.progress.weeklyVolume} height={88} /></div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 11, color: 'var(--text-3)', fontWeight: 600 }}><span>8 weeks ago</span><span>This week</span></div>
        </Card>

        {/* per-lift e1RM */}
        <SectionLabel style={{ marginTop: 22 }}>Estimated 1RM</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {PQ.exercises.filter(e => e.best1rm).slice(0, 4).map(e => (
            <Card key={e.id} pad="14px 16px" onClick={() => onExercise(e)}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, fontSize: 15 }}>{e.name}</div>
                  <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', marginTop: 4 }}>
                    <span style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-.02em' }}>{e.best1rm}</span>
                    <span style={{ fontSize: 12, color: 'var(--text-3)', fontWeight: 600 }}> lb</span>
                    <span style={{ color: 'var(--success)', fontSize: 12, fontWeight: 700, marginLeft: 8 }}>▲ {e.e1rmDelta}</span>
                  </div>
                </div>
                <div style={{ width: 110, height: 44 }}><LineChart data={e.history1rm} height={44} area={false} dot /></div>
              </div>
            </Card>
          ))}
        </div>

        {/* Pro locked */}
        <div onClick={onPaywall} style={{ marginTop: 18, cursor: 'pointer', borderRadius: 'var(--r-lg)', border: '1px solid var(--hairline)', overflow: 'hidden', position: 'relative', background: 'var(--surface)', padding: 'var(--s5)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 42, height: 42, borderRadius: 'var(--r-sm)', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center' }}>
              <Icon name="lock" size={20} color="var(--accent)" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 15 }}>Plateau detection & full history</div>
              <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 2 }}>Unlock with Physique Pro</div>
            </div>
            <Icon name="chevR" size={18} color="var(--text-3)" />
          </div>
        </div>
      </div>
    </Screen>
  );
}

Object.assign(window, { Screen, ScreenHeader, SectionLabel, StatTile, TabBar, HomeScreen, HistoryScreen, ExercisesScreen, ProgressScreen, BodyweightCard, BodyweightModal, relDay, fullDay });
