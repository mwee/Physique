/* PHYSIQUE — App root: navigation, tweaks, theme */

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#3B7BF6",
  "appearance": "dark",
  "typeface": "System",
  "corners": "Default",
  "density": "Regular",
  "dataState": "Populated"
}/*EDITMODE-END*/;

const FONTS = {
  System: '-apple-system, "SF Pro Text", system-ui, sans-serif',
  Plex: '"IBM Plex Sans", system-ui, sans-serif',
  Display: '"Space Grotesk", system-ui, sans-serif',
};
const RSCALE = { Sharp: 0.5, Default: 1, Rounded: 1.5 };
const DSCALE = { Compact: 0.9, Regular: 1, Roomy: 1.14 };
const ACCENTS = ['#3B7BF6', '#F26A1B', '#7C5CFF', '#17A86B'];

function Toast({ msg }) {
  if (!msg) return null;
  return (
    <div style={{
      position: 'absolute', bottom: 110, left: '50%', transform: 'translateX(-50%)', zIndex: 80,
      background: 'var(--surface)', color: 'var(--text)', borderRadius: 'var(--r-full)',
      padding: '11px 18px', fontWeight: 600, fontSize: 14, whiteSpace: 'nowrap',
      boxShadow: 'var(--shadow-lg)', border: '1px solid var(--hairline)',
      animation: 'pqUp .25s ease', maxWidth: 340,
    }}>{msg}</div>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [tab, setTab] = useState('home');
  const [mode, setMode] = useState('template');
  const [stack, setStack] = useState([]);  // overlay screens
  const [toast, setToast] = useState(null);
  const toastT = useRef(null);
  // first-run onboarding — shows once, persisted; replayable from Tweaks
  const [onboarding, setOnboarding] = useState(() => {
    try { return localStorage.getItem('pq_onboarded') !== '1'; } catch (e) { return true; }
  });
  const empty = t.dataState === 'Empty';
  // Active program (saved from the template library) — schedules the Plan tab.
  const [activeProgram, setActiveProgram] = useState(() => {
    try { const v = JSON.parse(localStorage.getItem('pq_active_program_lb')); if (v && v.programId) return v; } catch (e) {}
    return { programId: '531bbb', maxes: { ...window.TPL.defaults.lb }, tmPct: 90, warmups: false, week: 0 };
  });
  useEffect(() => { try { localStorage.setItem('pq_active_program_lb', JSON.stringify(activeProgram)); } catch (e) {} }, [activeProgram]);

  const finishOnboarding = (answers) => {
    try { localStorage.setItem('pq_onboarded', '1'); } catch (e) {}
    if (answers && answers.path === 'coach') { setMode('coach'); setTab('plan'); }
    setOnboarding(false);
  };

  const isDark = t.appearance === 'dark';
  const push = (item) => setStack(s => [...s, item]);
  const pop = () => setStack(s => s.slice(0, -1));

  const showToast = (msg) => {
    setToast(msg);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(null), 2400);
  };

  // ---- Template library / program scheduling ----
  const activeProg = activeProgram ? window.TPL.programs.find(p => p.id === activeProgram.programId) : null;
  const openLibrary = () => push({ type: 'library' });
  const activateProgram = (cfg) => { setActiveProgram(cfg); setStack([]); setTab('plan'); const p = window.TPL.programs.find(x => x.id === cfg.programId); showToast(`Scheduled · ${p.name}`); };
  const startSession = (dayIndex) => { const s = window.tplBuildSessionPlan(activeProgram, dayIndex); push({ type: 'workout', plan: s.exercises, title: s.title }); };
  const changeWeek = (delta) => setActiveProgram(ap => { const max = (window.TPL.programs.find(p => p.id === ap.programId).cycleWeeks || 1) - 1; return { ...ap, week: Math.min(max, Math.max(0, (ap.week || 0) + delta)) }; });
  const adjustProgram = () => push({ type: 'program', prog: activeProg, initial: activeProgram });

  const rootStyle = {
    '--accent': t.accent,
    '--on-accent': '#ffffff',
    '--r-scale': RSCALE[t.corners] ?? 1,
    '--d-scale': DSCALE[t.density] ?? 1,
    fontFamily: FONTS[t.typeface] || FONTS.System,
  };

  const tabScreen = () => {
    switch (tab) {
      case 'home':
        return <HomeScreen empty={empty} onStart={() => push({ type: 'workout' })} onRoutines={() => setTab('plan')} onCoach={() => { setMode('coach'); setTab('plan'); }} onSession={(s) => push({ type: 'session', data: s })} onProgress={() => setTab('progress')} onPaywall={() => push({ type: 'paywall' })} />;
      case 'plan':
        return <PlanScreen empty={empty} mode={mode} onMode={setMode}
          activeProgram={empty ? null : activeProgram}
          onBrowse={openLibrary}
          onStartSession={startSession}
          onWeek={changeWeek}
          onAdjust={adjustProgram}
          onStartRoutine={() => push({ type: 'workout' })}
          onStartCoached={(plan, title) => push({ type: 'workout', plan, title, coached: true })}
          onToast={showToast} />;
      case 'history': return <HistoryScreen empty={empty} onSession={(s) => push({ type: 'session', data: s })} onStart={() => push({ type: 'workout' })} />;
      case 'exercises': return <ExercisesScreen onExercise={(e) => push({ type: 'exercise', data: e })} />;
      case 'progress': return <ProgressScreen empty={empty} onExercise={(e) => push({ type: 'exercise', data: e })} onPaywall={() => push({ type: 'paywall' })} onLog={() => showToast('Bodyweight logged · 78.4 kg')} onBodyweight={() => push({ type: 'bodyweight' })} onStart={() => push({ type: 'workout' })} />;
      default: return null;
    }
  };

  return (
    <div>
      <IOSDevice dark={isDark} width={402} height={874}>
        <div className="pq-root" data-theme={t.appearance} style={rootStyle}>
          <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)', color: 'var(--text)' }}>
            {tabScreen()}
            <TabBar tab={tab} onTab={(id) => { setStack([]); setTab(id); }} />

            {stack.map((item, i) => {
              const z = 30 + i * 5;
              const wrap = (el) => <div key={i} style={{ position: 'absolute', inset: 0, zIndex: z }}>{el}</div>;
              if (item.type === 'workout') return wrap(<ActiveWorkout plan={item.plan} title={item.title} coached={item.coached} onFinish={(r) => { pop(); setTab('history'); showToast(`Workout saved · ${r.dur} · ${r.sets} sets`); }} onCancel={() => { pop(); showToast('Workout discarded'); }} onToast={showToast} />);
              if (item.type === 'session') return wrap(<SessionDetail session={item.data} onBack={pop} />);
              if (item.type === 'exercise') return wrap(<ExerciseDetail ex={item.data} onBack={pop} onPaywall={() => push({ type: 'paywall' })} />);
              if (item.type === 'routines') return wrap(<RoutinesScreen onBack={pop} onStart={() => { pop(); push({ type: 'workout' }); }} />);
              if (item.type === 'paywall') return wrap(<Paywall onClose={pop} />);
              if (item.type === 'bodyweight') return wrap(<BodyweightModal onClose={pop} onLog={() => showToast('Bodyweight logged · 78.4 kg')} />);
              if (item.type === 'library') return wrap(<LibraryBrowseScreen activeId={activeProgram && activeProgram.programId} onBack={pop} onOpen={(prog) => push({ type: 'program', prog, initial: activeProgram && activeProgram.programId === prog.id ? activeProgram : null })} />);
              if (item.type === 'program') return wrap(<ProgramDetailScreen prog={item.prog} initial={item.initial} onBack={pop} onActivate={activateProgram} />);
              return null;
            })}

            <Toast msg={toast} />
            {onboarding && <OnboardingFlow onDone={finishOnboarding} />}
          </div>
        </div>
      </IOSDevice>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Appearance" />
        <TweakRadio label="Theme" value={t.appearance} options={['dark', 'light']} onChange={(v) => setTweak('appearance', v)} />
        <TweakColor label="Accent" value={t.accent} options={ACCENTS} onChange={(v) => setTweak('accent', v)} />
        <TweakSection label="Type & shape" />
        <TweakRadio label="Typeface" value={t.typeface} options={['System', 'Plex', 'Display']} onChange={(v) => setTweak('typeface', v)} />
        <TweakRadio label="Corners" value={t.corners} options={['Sharp', 'Default', 'Rounded']} onChange={(v) => setTweak('corners', v)} />
        <TweakRadio label="Density" value={t.density} options={['Compact', 'Regular', 'Roomy']} onChange={(v) => setTweak('density', v)} />
        <TweakSection label="First-run" />
        <TweakRadio label="App data" value={t.dataState || 'Populated'} options={['Populated', 'Empty']} onChange={(v) => setTweak('dataState', v)} />
        <TweakButton label="Replay onboarding" onClick={() => { setStack([]); setTab('home'); setOnboarding(true); }} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
