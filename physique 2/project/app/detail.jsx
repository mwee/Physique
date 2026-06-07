/* PHYSIQUE — pushed & sheet screens (SessionDetail, ExerciseDetail, Routines, Paywall) */

function PushHeader({ title, onBack, trailing }) {
  return (
    <div style={{
      position: 'sticky', top: 0, zIndex: 10, paddingTop: SAFE_TOP,
      background: 'color-mix(in srgb, var(--bg) 82%, transparent)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderBottom: '1px solid var(--hairline)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 12px 12px', minHeight: 44 }}>
        <button onClick={onBack} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 38, height: 38, display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
          <Icon name="chevL" size={20} color="var(--text)" sw={2.4} />
        </button>
        <div style={{ fontWeight: 700, fontSize: 18, flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
        {trailing}
      </div>
    </div>
  );
}

function PushScreen({ children, anim = 'right' }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 30, background: 'var(--bg)', overflowY: 'auto', WebkitOverflowScrolling: 'touch',
      paddingBottom: 40, animation: anim === 'up' ? 'pqUp .3s cubic-bezier(.2,.8,.2,1)' : 'pqSlideIn .28s cubic-bezier(.2,.8,.2,1)',
    }}>{children}</div>
  );
}

// ---------- Session detail ----------
function SessionDetail({ session, onBack }) {
  return (
    <PushScreen>
      <PushHeader title={session.name} onBack={onBack} trailing={session.prs > 0 ? <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> {session.prs}</Pill> : null} />
      <div style={{ padding: '16px 16px 0' }}>
        <div style={{ color: 'var(--text-3)', fontSize: 14, fontWeight: 600 }}>{session.date.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' })}</div>
        <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
          <StatTile label="Duration" value={session.dur} />
          <StatTile label="Volume" value={(session.volume / 1000).toFixed(1) + 'k'} unit="lb" />
          <StatTile label="Sets" value={session.sets} />
        </div>
        <SectionLabel style={{ marginTop: 22 }}>Exercises</SectionLabel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {session.detail.map((ex, i) => (
            <Card key={i} pad="0">
              <div style={{ padding: '14px 16px 8px', fontWeight: 700, fontSize: 16, color: 'var(--accent)' }}>{ex.name}</div>
              {ex.sets.map((st, j) => {
                const pr = st.includes('★');
                const clean = st.replace('★', '').trim();
                const warm = clean.endsWith('W');
                const txt = clean.replace('W', '').trim();
                return (
                  <div key={j} style={{ display: 'flex', alignItems: 'center', padding: '9px 16px', borderTop: '1px solid var(--hairline)', gap: 12 }}>
                    <span style={{ width: 24, fontWeight: 700, color: warm ? 'var(--warmup)' : 'var(--text-2)', fontFamily: 'var(--font-num)' }}>{warm ? 'W' : j + (ex.sets[0].includes('W') ? 0 : 1)}</span>
                    <span style={{ flex: 1, fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 15, fontWeight: 600 }}>{txt}<span style={{ color: 'var(--text-3)', fontWeight: 600 }}> kg</span></span>
                    {pr && <Pill tone="pr"><Icon name="flame" size={11} color="var(--pr)" fill /> PR</Pill>}
                  </div>
                );
              })}
            </Card>
          ))}
        </div>
      </div>
    </PushScreen>
  );
}

// ---------- Exercise detail ----------
function ExerciseDetail({ ex, onBack, onPaywall }) {
  const [range, setRange] = useState('8W');
  const recent = [
    { d: '2 days ago', sets: '160 × 1 ★, 140 × 3, 120 × 5' },
    { d: '9 days ago', sets: '155 × 1, 135 × 3, 120 × 5' },
    { d: '16 days ago', sets: '150 × 1, 130 × 3, 115 × 5' },
  ];
  return (
    <PushScreen>
      <PushHeader title={ex.name} onBack={onBack} trailing={<button style={{ border: 0, background: 'transparent', cursor: 'pointer' }}><Icon name="ellipsis" size={22} color="var(--text-2)" sw={2.6} /></button>} />
      <div style={{ padding: '14px 16px 0' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <Pill tone="neutral" style={{ textTransform: 'capitalize' }}>{ex.group}</Pill>
          <Pill tone="neutral" style={{ textTransform: 'capitalize' }}>{ex.type}</Pill>
        </div>

        {/* chart card */}
        <Card style={{ marginTop: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ fontWeight: 600, fontSize: 15, color: 'var(--text-2)' }}>Estimated 1RM</span>
            {ex.e1rmDelta > 0 && <span style={{ color: 'var(--success)', fontWeight: 700, fontSize: 13 }}>▲ {ex.e1rmDelta} lb</span>}
          </div>
          <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 40, fontWeight: 700, letterSpacing: '-.03em', marginTop: 4 }}>
            {ex.best1rm || '—'}<span style={{ fontSize: 16, color: 'var(--text-3)', fontWeight: 600 }}> lb</span>
          </div>
          <div style={{ marginTop: 12 }}><LineChart data={ex.history1rm} height={130} /></div>
          <div style={{ display: 'flex', gap: 6, marginTop: 14, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', padding: 4 }}>
            {['8W', '6M', '1Y', 'All'].map(r => (
              <button key={r} onClick={() => setRange(r)} style={{ flex: 1, border: 0, cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '7px 0', fontSize: 13, fontWeight: 600, fontFamily: 'var(--font)', background: range === r ? 'var(--surface)' : 'transparent', color: range === r ? 'var(--text)' : 'var(--text-2)', boxShadow: range === r ? 'var(--shadow-sm)' : 'none' }}>{r}</button>
            ))}
          </div>
        </Card>

        {/* records */}
        <SectionLabel style={{ marginTop: 22 }}>Personal records</SectionLabel>
        <Card pad="0">
          {[['Heaviest weight', ex.records.weight], ['Best estimated 1RM', ex.records.e1rm], ['Best session volume', ex.records.volume]].map(([l, v], i) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
              <span style={{ color: 'var(--text-2)', fontSize: 14 }}>{l}</span>
              <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', gap: 6 }}><Icon name="flame" size={13} color="var(--pr)" fill /> {v}</span>
            </div>
          ))}
        </Card>

        {/* recent sessions */}
        <SectionLabel style={{ marginTop: 22 }}>Recent sessions</SectionLabel>
        <Card pad="0">
          {recent.map((r, i) => (
            <div key={i} style={{ padding: '13px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
              <div style={{ color: 'var(--text-3)', fontSize: 12, fontWeight: 600 }}>{r.d}</div>
              <div style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 14, marginTop: 3 }}>{r.sets}</div>
            </div>
          ))}
        </Card>
      </div>
    </PushScreen>
  );
}

// ---------- Routines ----------
function RoutinesScreen({ onBack, onStart }) {
  return (
    <PushScreen>
      <PushHeader title="Routines" onBack={onBack} trailing={<button style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 38, height: 38, display: 'grid', placeItems: 'center', cursor: 'pointer' }}><Icon name="plus" size={20} color="var(--accent)" sw={2.4} /></button>} />
      <div style={{ padding: '14px 16px 0' }}>
        {PQ.folders.map(f => (
          <div key={f.id} style={{ marginBottom: 24 }}>
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
    </PushScreen>
  );
}

// ---------- Paywall ----------
function Paywall({ onClose }) {
  const [plan, setPlan] = useState('annual');
  const features = [
    ['chart', 'Unlimited routines & full history', 'Free keeps your last 30 days and 3 routines.'],
    ['progress', 'Every chart & plateau detection', '1RM trends, volume, plateau & PR-due nudges.'],
    ['timer', 'Rest-timer customization', 'Per-exercise defaults, background notifications.'],
    ['bolt', 'Cloud backup & sync', 'Your log, safe across every device.'],
  ];
  return (
    <PushScreen anim="up">
      <div style={{ paddingTop: SAFE_TOP }}>
        <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '6px 14px' }}>
          <button onClick={onClose} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 34, height: 34, display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
            <Icon name="x" size={17} color="var(--text-2)" sw={2.4} />
          </button>
        </div>
        <div style={{ padding: '6px 24px 0', textAlign: 'center' }}>
          <div style={{ width: 56, height: 56, borderRadius: 'var(--r-md)', background: 'var(--accent)', display: 'grid', placeItems: 'center', margin: '0 auto 16px', boxShadow: '0 10px 30px var(--accent-soft)' }}>
            <Icon name="bolt" size={28} color="var(--on-accent)" fill />
          </div>
          <h1 style={{ margin: 0, fontSize: 30, fontWeight: 700, letterSpacing: '-.02em' }}>Physique Pro</h1>
          <p style={{ color: 'var(--text-2)', fontSize: 15, margin: '8px 0 0', lineHeight: 1.5 }}>Everything you need to keep getting stronger — no ads, ever.</p>
        </div>

        <div style={{ padding: '24px 20px 0', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {features.map(([ic, t, d]) => (
            <div key={t} style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <div style={{ width: 38, height: 38, borderRadius: 'var(--r-sm)', background: 'var(--accent-soft)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                <Icon name={ic} size={19} color="var(--accent)" />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 15 }}>{t}</div>
                <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 2, lineHeight: 1.4 }}>{d}</div>
              </div>
            </div>
          ))}
        </div>

        <div style={{ padding: '24px 20px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[['annual', 'Annual', '$29.99 / yr', 'Just $2.50/mo · save 40%'], ['monthly', 'Monthly', '$3.99 / mo', 'Billed monthly']].map(([id, t, price, sub]) => {
            const sel = plan === id;
            return (
              <button key={id} onClick={() => setPlan(id)} style={{ textAlign: 'left', cursor: 'pointer', border: sel ? '2px solid var(--accent)' : '1px solid var(--hairline)', background: sel ? 'var(--accent-tint)' : 'var(--surface)', borderRadius: 'var(--r-md)', padding: '14px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 16, display: 'flex', alignItems: 'center', gap: 8 }}>{t} {id === 'annual' && <Pill tone="accent">Best value</Pill>}</div>
                  <div style={{ color: 'var(--text-2)', fontSize: 12, marginTop: 3 }}>{sub}</div>
                </div>
                <div style={{ fontFamily: 'var(--font-num)', fontWeight: 700, fontSize: 16 }}>{price}</div>
              </button>
            );
          })}
        </div>

        <div style={{ padding: '20px 20px 8px' }}>
          <Btn onClick={onClose}>Start 7-day free trial</Btn>
          <div style={{ textAlign: 'center', color: 'var(--text-3)', fontSize: 12, marginTop: 12, lineHeight: 1.5 }}>Then {plan === 'annual' ? '$29.99/yr' : '$3.99/mo'}. Cancel anytime.<br />Restore purchase · Terms · Privacy</div>
        </div>
      </div>
    </PushScreen>
  );
}

Object.assign(window, { PushHeader, PushScreen, SessionDetail, ExerciseDetail, RoutinesScreen, Paywall });
