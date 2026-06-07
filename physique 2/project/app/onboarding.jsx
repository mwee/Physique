/* PHYSIQUE — first-run onboarding (premium, one decision per screen) */

// brand mark
function Mark({ size = 64 }) {
  return (
    <div style={{ width: size, height: size, borderRadius: size * 0.28, background: 'var(--accent)', display: 'grid', placeItems: 'center', boxShadow: '0 14px 40px var(--accent-soft)' }}>
      <svg width={size * 0.56} height={size * 0.56} viewBox="0 0 20 20" fill="none">
        <path d="M3 15.5L7.2 8.2L10.4 11.6L16.5 4" stroke="var(--on-accent)" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="16.6" cy="4" r="1.7" fill="var(--on-accent)" />
      </svg>
    </div>
  );
}

// selectable option card
function OptCard({ icon, title, sub, selected, onClick, badge }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', textAlign: 'left', cursor: 'pointer', fontFamily: 'var(--font)',
      display: 'flex', alignItems: 'center', gap: 14, padding: '16px',
      borderRadius: 'var(--r-md)', transition: 'all .15s ease',
      background: selected ? 'var(--accent-tint)' : 'var(--surface)',
      border: selected ? '2px solid var(--accent)' : '1px solid var(--hairline)',
      WebkitTapHighlightColor: 'transparent',
    }}>
      {icon && (
        <div style={{ width: 42, height: 42, borderRadius: 'var(--r-sm)', flexShrink: 0, display: 'grid', placeItems: 'center', background: selected ? 'var(--accent)' : 'var(--surface-2)' }}>
          <Icon name={icon} size={21} color={selected ? 'var(--on-accent)' : 'var(--text-2)'} fill={selected} />
        </div>
      )}
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontWeight: 600, fontSize: 16 }}>{title}</span>
          {badge && <Pill tone="accent">{badge}</Pill>}
        </div>
        {sub && <div style={{ color: 'var(--text-2)', fontSize: 13, marginTop: 3, lineHeight: 1.4 }}>{sub}</div>}
      </div>
      <div style={{ width: 22, height: 22, borderRadius: '50%', flexShrink: 0, display: 'grid', placeItems: 'center', border: selected ? '0' : '2px solid var(--hairline-strong)', background: selected ? 'var(--accent)' : 'transparent' }}>
        {selected && <Icon name="check" size={13} color="var(--on-accent)" sw={3} />}
      </div>
    </button>
  );
}

function OnboardingFlow({ onDone }) {
  const STEPS = ['welcome', 'goal', 'level', 'schedule', 'path', 'ready'];
  const [step, setStep] = useState(0);
  const [a, setA] = useState({ goal: null, level: null, days: 4, units: 'lb', path: null });
  const [building, setBuilding] = useState(false);
  const set = (k, v) => setA(p => ({ ...p, [k]: v }));
  const key = STEPS[step];
  const go = (n) => setStep(s => Math.max(0, Math.min(STEPS.length - 1, s + n)));

  // entering "ready" shows a brief building moment
  const next = () => {
    if (key === 'path') {
      setBuilding(true);
      setTimeout(() => { setBuilding(false); setStep(s => s + 1); }, 1400);
      return;
    }
    go(1);
  };

  const canContinue = (
    key === 'welcome' ||
    (key === 'goal' && a.goal) ||
    (key === 'level' && a.level) ||
    key === 'schedule' ||
    (key === 'path' && a.path) ||
    key === 'ready'
  );

  const progress = step / (STEPS.length - 1);

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 90, background: 'var(--bg)', display: 'flex', flexDirection: 'column', fontFamily: 'var(--font)' }}>
      {/* top bar: back + progress */}
      {key !== 'welcome' && key !== 'ready' && (
        <div style={{ paddingTop: SAFE_TOP, padding: `${SAFE_TOP}px 20px 0` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <button onClick={() => go(-1)} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 36, height: 36, display: 'grid', placeItems: 'center', cursor: 'pointer', flexShrink: 0 }}>
              <Icon name="chevL" size={19} color="var(--text)" sw={2.4} />
            </button>
            <div style={{ flex: 1, height: 5, background: 'var(--surface-2)', borderRadius: 999, overflow: 'hidden' }}>
              <div style={{ height: '100%', width: `${progress * 100}%`, background: 'var(--accent)', borderRadius: 999, transition: 'width .3s ease' }} />
            </div>
          </div>
        </div>
      )}

      {/* content */}
      <div key={key} style={{ flex: 1, overflowY: 'auto', padding: '0 20px', animation: 'pqStep .32s cubic-bezier(.2,.8,.2,1)' }}>
        {building ? (
          <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 20, textAlign: 'center' }}>
            <div style={{ position: 'relative', width: 64, height: 64 }}>
              <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', border: '3px solid var(--accent-soft)', borderTopColor: 'var(--accent)', animation: 'pqSpin .8s linear infinite' }} />
              <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center' }}><Icon name="spark" size={26} color="var(--accent)" fill /></div>
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 20 }}>Building your plan</div>
              <div style={{ color: 'var(--text-2)', fontSize: 14, marginTop: 6 }}>Tailoring movements to your goal and experience…</div>
            </div>
          </div>
        ) : key === 'welcome' ? (
          <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', paddingBottom: 40 }}>
            <Mark size={76} />
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '.16em', textTransform: 'uppercase', color: 'var(--accent)', marginTop: 26 }}>Physique</div>
            <h1 style={{ fontSize: 38, fontWeight: 700, letterSpacing: '-.03em', lineHeight: 1.05, margin: '14px 0 0' }}>Train with<br /><span style={{ color: 'var(--text-2)', fontWeight: 300 }}>intention.</span></h1>
            <p style={{ color: 'var(--text-2)', fontSize: 16, lineHeight: 1.5, margin: '18px 0 0', maxWidth: 320 }}>The premium logbook for serious lifters — fast to log, smart about your progress.</p>
          </div>
        ) : key === 'goal' ? (
          <div style={{ paddingTop: 24 }}>
            <h2 style={{ fontSize: 27, fontWeight: 700, letterSpacing: '-.02em', margin: 0 }}>What's your goal?</h2>
            <p style={{ color: 'var(--text-2)', fontSize: 15, margin: '8px 0 22px' }}>We'll shape your training around it.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <OptCard icon="dumbbell" title="Build muscle" sub="Hypertrophy — moderate reps, steady volume" selected={a.goal === 'Build muscle'} onClick={() => set('goal', 'Build muscle')} />
              <OptCard icon="bolt" title="Get stronger" sub="Lower reps, heavier loads, longer rest" selected={a.goal === 'Get stronger'} onClick={() => set('goal', 'Get stronger')} />
              <OptCard icon="flame" title="Lose fat" sub="Higher density, keep the muscle you've built" selected={a.goal === 'Lose fat'} onClick={() => set('goal', 'Lose fat')} />
              <OptCard icon="progress" title="Stay healthy" sub="Balanced full-body, sustainable pace" selected={a.goal === 'Stay healthy'} onClick={() => set('goal', 'Stay healthy')} />
            </div>
          </div>
        ) : key === 'level' ? (
          <div style={{ paddingTop: 24 }}>
            <h2 style={{ fontSize: 27, fontWeight: 700, letterSpacing: '-.02em', margin: 0 }}>How much have you lifted?</h2>
            <p style={{ color: 'var(--text-2)', fontSize: 15, margin: '8px 0 22px' }}>This sets your starting loads and guidance.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <OptCard title="New to lifting" sub="Just starting — I'd like guidance" selected={a.level === 'Beginner'} onClick={() => set('level', 'Beginner')} />
              <OptCard title="Getting back into it" sub="Lifted before, returning after a break" selected={a.level === 'Returning'} onClick={() => set('level', 'Returning')} />
              <OptCard title="Train regularly" sub="Consistent for a year or more" selected={a.level === 'Intermediate'} onClick={() => set('level', 'Intermediate')} />
              <OptCard title="Advanced" sub="I know my numbers and program myself" selected={a.level === 'Advanced'} onClick={() => set('level', 'Advanced')} />
            </div>
          </div>
        ) : key === 'schedule' ? (
          <div style={{ paddingTop: 24 }}>
            <h2 style={{ fontSize: 27, fontWeight: 700, letterSpacing: '-.02em', margin: 0 }}>Set your rhythm</h2>
            <p style={{ color: 'var(--text-2)', fontSize: 15, margin: '8px 0 22px' }}>You can change these anytime.</p>

            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 'var(--r-md)', padding: 'var(--s5)' }}>
              <div style={{ fontSize: 13, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em', color: 'var(--text-3)' }}>Days per week</div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16 }}>
                <button onClick={() => set('days', Math.max(2, a.days - 1))} style={{ border: 0, background: 'var(--surface-2)', borderRadius: 'var(--r-full)', width: 44, height: 44, display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
                  <span style={{ fontSize: 24, color: 'var(--text)', lineHeight: 1 }}>−</span>
                </button>
                <div style={{ textAlign: 'center' }}>
                  <span style={{ fontFamily: 'var(--font-num)', fontVariantNumeric: 'tabular-nums', fontSize: 42, fontWeight: 700, letterSpacing: '-.02em' }}>{a.days}</span>
                  <div style={{ color: 'var(--text-3)', fontSize: 13, fontWeight: 600 }}>days / week</div>
                </div>
                <button onClick={() => set('days', Math.min(6, a.days + 1))} style={{ border: 0, background: 'var(--accent)', borderRadius: 'var(--r-full)', width: 44, height: 44, display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
                  <span style={{ fontSize: 24, color: 'var(--on-accent)', lineHeight: 1 }}>+</span>
                </button>
              </div>
            </div>

            <div style={{ background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 'var(--r-md)', padding: 'var(--s5)', marginTop: 12 }}>
              <div style={{ fontSize: 13, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.05em', color: 'var(--text-3)', marginBottom: 14 }}>Units</div>
              <div style={{ display: 'flex', background: 'var(--surface-2)', borderRadius: 'var(--r-full)', padding: 4, gap: 4 }}>
                {['kg', 'lb'].map(u => (
                  <button key={u} onClick={() => set('units', u)} style={{ flex: 1, border: 0, cursor: 'pointer', borderRadius: 'var(--r-full)', padding: '11px 0', fontWeight: 600, fontSize: 15, fontFamily: 'var(--font)', background: a.units === u ? 'var(--accent)' : 'transparent', color: a.units === u ? 'var(--on-accent)' : 'var(--text-2)' }}>{u === 'kg' ? 'Kilograms (kg)' : 'Pounds (lb)'}</button>
                ))}
              </div>
            </div>
          </div>
        ) : key === 'path' ? (
          <div style={{ paddingTop: 24 }}>
            <h2 style={{ fontSize: 27, fontWeight: 700, letterSpacing: '-.02em', margin: 0 }}>How do you want to train?</h2>
            <p style={{ color: 'var(--text-2)', fontSize: 15, margin: '8px 0 22px' }}>Switch between these anytime in the Plan tab.</p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <OptCard icon="spark" title="Coach me" sub="AI builds each session and guides your form — best if you're newer." badge="Recommended" selected={a.path === 'coach'} onClick={() => set('path', 'coach')} />
              <OptCard icon="clipboard" title="I'll build my own" sub="Create routines and templates yourself." selected={a.path === 'template'} onClick={() => set('path', 'template')} />
            </div>
          </div>
        ) : ( // ready
          <div style={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', paddingBottom: 30 }}>
            <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'var(--accent)', display: 'grid', placeItems: 'center', boxShadow: '0 14px 40px var(--accent-soft)' }}>
              <Icon name="check" size={32} color="var(--on-accent)" sw={2.6} />
            </div>
            <h1 style={{ fontSize: 30, fontWeight: 700, letterSpacing: '-.02em', margin: '22px 0 0' }}>You're all set</h1>
            <p style={{ color: 'var(--text-2)', fontSize: 15, lineHeight: 1.5, margin: '10px 0 24px', maxWidth: 300 }}>
              {a.path === 'coach' ? 'Your coach has your first session ready in the Plan tab.' : 'Build your first routine in the Plan tab whenever you\u2019re ready.'}
            </p>
            <div style={{ width: '100%', maxWidth: 320, background: 'var(--surface)', border: '1px solid var(--hairline)', borderRadius: 'var(--r-md)', overflow: 'hidden' }}>
              {[['Goal', a.goal], ['Experience', a.level === 'Beginner' ? 'New to lifting' : a.level], ['Schedule', `${a.days} days / week`], ['Units', a.units], ['Mode', a.path === 'coach' ? 'AI Coach' : 'Templates']].map(([l, v], i) => (
                <div key={l} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 16px', borderTop: i ? '1px solid var(--hairline)' : 0 }}>
                  <span style={{ color: 'var(--text-2)', fontSize: 14 }}>{l}</span>
                  <span style={{ fontWeight: 600, fontSize: 14 }}>{v}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* bottom CTA */}
      {!building && (
        <div style={{ padding: '12px 20px 30px' }}>
          <Btn onClick={key === 'ready' ? () => onDone(a) : next} style={{ opacity: canContinue ? 1 : 0.4, pointerEvents: canContinue ? 'auto' : 'none' }}>
            {key === 'welcome' ? 'Get started' : key === 'ready' ? 'Enter Physique' : key === 'path' ? 'Build my plan' : 'Continue'}
          </Btn>
          {key === 'welcome' && (
            <button onClick={() => onDone(a)} style={{ width: '100%', border: 0, background: 'transparent', color: 'var(--text-2)', cursor: 'pointer', fontWeight: 600, fontSize: 14, padding: '14px 0 0', fontFamily: 'var(--font)' }}>I already have an account</button>
          )}
        </div>
      )}
    </div>
  );
}

Object.assign(window, { OnboardingFlow });
