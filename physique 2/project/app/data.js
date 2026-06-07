/* PHYSIQUE — mock data (window.PQ) — pounds (lb) */
(function () {
  const today = new Date(2026, 4, 30); // May 30 2026
  const d = (daysAgo) => {
    const x = new Date(today); x.setDate(x.getDate() - daysAgo); return x;
  };

  // ---- Exercise library ----
  const exercises = [
    { id: 'deadlift', name: 'Deadlift', group: 'Back', type: 'barbell', best1rm: 400, bestWeight: 355, e1rmDelta: 14.5,
      note: 'Watch back rounding',
      history1rm: [350, 355, 355, 370, 380, 375, 390, 400],
      records: { weight: '355 lb × 1', e1rm: '400 lb', volume: '10,630 lb' } },
    { id: 'bench', name: 'Bench Press', group: 'Chest', type: 'barbell', best1rm: 260, bestWeight: 230, e1rmDelta: 5.5,
      history1rm: [230, 240, 235, 245, 245, 250, 255, 260],
      records: { weight: '230 lb × 1', e1rm: '260 lb', volume: '6,880 lb' } },
    { id: 'squat', name: 'Back Squat', group: 'Legs', type: 'barbell', best1rm: 365, bestWeight: 330, e1rmDelta: 9.0,
      history1rm: [330, 335, 335, 345, 350, 355, 355, 365],
      records: { weight: '330 lb × 1', e1rm: '365 lb', volume: '11,910 lb' } },
    { id: 'ohp', name: 'Overhead Press', group: 'Shoulders', type: 'barbell', best1rm: 160, bestWeight: 135, e1rmDelta: 2.0,
      history1rm: [145, 150, 150, 150, 155, 155, 155, 160],
      records: { weight: '135 lb × 2', e1rm: '160 lb', volume: '4,100 lb' } },
    { id: 'row', name: 'Barbell Row', group: 'Back', type: 'barbell', best1rm: 245, bestWeight: 220, e1rmDelta: 6.5,
      history1rm: [215, 220, 220, 230, 230, 235, 240, 245],
      records: { weight: '220 lb × 2', e1rm: '245 lb', volume: '6,480 lb' } },
    { id: 'pullup', name: 'Pull Up', group: 'Back', type: 'bodyweight', best1rm: null, bestWeight: null, e1rmDelta: 0,
      history1rm: [8, 9, 9, 10, 11, 11, 12, 13],
      records: { weight: 'BW + 45 lb × 5', e1rm: '—', volume: '—' } },
    { id: 'curl', name: 'Dumbbell Curl', group: 'Arms', type: 'dumbbell', best1rm: 55, bestWeight: 50, e1rmDelta: 1.0,
      history1rm: [45, 45, 45, 50, 50, 50, 50, 55],
      records: { weight: '50 lb × 8', e1rm: '55 lb', volume: '2,470 lb' } },
    { id: 'lat', name: 'Lat Pulldown', group: 'Back', type: 'machine', best1rm: 200, bestWeight: 175, e1rmDelta: 4.5,
      history1rm: [175, 180, 180, 185, 185, 190, 195, 200],
      records: { weight: '175 lb × 6', e1rm: '200 lb', volume: '4,760 lb' } },
  ];

  // ---- Active workout template (the hero) ----
  const activeWorkout = {
    name: 'Morning Workout',
    exercises: [
      { exId: 'deadlift', name: 'Deadlift', note: 'Watch back rounding',
        sets: [
          { type: 'W', prev: { w: 135, r: 5 }, w: 135, r: 5, done: true },
          { type: 1, prev: { w: 220, r: 3 }, w: 220, r: 3, done: true },
          { type: 2, prev: { w: 265, r: 1 }, w: 265, r: 1, done: true },
          { type: 3, prev: { w: 300, r: 5 }, w: 285, r: 5, done: false },
        ] },
      { exId: 'bench', name: 'Bench Press', note: null,
        sets: [
          { type: 'W', prev: { w: 90, r: 8 }, w: 90, r: 8, done: false },
          { type: 1, prev: { w: 175, r: 6 }, w: 175, r: 6, done: false },
          { type: 2, prev: { w: 200, r: 4 }, w: 200, r: 4, done: false },
          { type: 3, prev: { w: 210, r: 3 }, w: 210, r: 3, done: false },
        ] },
      { exId: 'row', name: 'Barbell Row', note: null,
        sets: [
          { type: 1, prev: { w: 155, r: 8 }, w: 155, r: 8, done: false },
          { type: 2, prev: { w: 175, r: 6 }, w: 175, r: 6, done: false },
          { type: 3, prev: { w: 185, r: 6 }, w: 185, r: 6, done: false },
        ] },
    ],
  };

  // ---- Routines / folders ----
  const folders = [
    { id: 'ppl', name: 'PPL Block 2', routines: [
      { id: 'push', name: 'Push Day', exercises: ['Bench Press', 'Overhead Press', 'Dumbbell Curl'], count: 6, last: '4 days ago' },
      { id: 'pull', name: 'Pull Day', exercises: ['Deadlift', 'Barbell Row', 'Pull Up'], count: 5, last: '2 days ago' },
      { id: 'legs', name: 'Leg Day', exercises: ['Back Squat', 'Romanian Deadlift'], count: 5, last: '6 days ago' },
    ] },
    { id: 'extra', name: 'Accessory', routines: [
      { id: 'arms', name: 'Arms & Delts', exercises: ['Dumbbell Curl', 'Lat Pulldown'], count: 7, last: '9 days ago' },
    ] },
  ];

  // ---- History sessions ----
  const history = [
    { id: 's1', name: 'Pull Day', date: d(2), dur: '1:04', volume: 27520, sets: 18, prs: 1,
      detail: [
        { name: 'Deadlift', sets: ['135×5 W', '220×5', '265×3', '310×2', '355×1 ★'] },
        { name: 'Barbell Row', sets: ['155×8', '175×6', '185×6'] },
        { name: 'Pull Up', sets: ['BW×10', 'BW×8', 'BW×7'] },
      ] },
    { id: 's2', name: 'Push Day', date: d(4), dur: '0:58', volume: 20550, sets: 16, prs: 0,
      detail: [
        { name: 'Bench Press', sets: ['90×8 W', '175×6', '200×4', '210×3'] },
        { name: 'Overhead Press', sets: ['90×8', '120×5', '130×4'] },
        { name: 'Dumbbell Curl', sets: ['40×10', '45×8', '50×6'] },
      ] },
    { id: 's3', name: 'Leg Day', date: d(6), dur: '1:12', volume: 31310, sets: 17, prs: 2,
      detail: [
        { name: 'Back Squat', sets: ['135×5 W', '265×5', '310×3', '355×1 ★'] },
        { name: 'Romanian Deadlift', sets: ['220×8', '245×6', '265×5 ★'] },
      ] },
    { id: 's4', name: 'Push Day', date: d(9), dur: '0:51', volume: 19320, sets: 15, prs: 0,
      detail: [{ name: 'Bench Press', sets: ['90×8 W', '170×6', '195×4', '205×3'] }] },
    { id: 's5', name: 'Pull Day', date: d(11), dur: '1:02', volume: 26240, sets: 18, prs: 1,
      detail: [{ name: 'Deadlift', sets: ['135×5 W', '220×5', '285×3', '340×1 ★'] }] },
  ];

  // ---- Progress dashboard ----
  const progress = {
    weeklyVolume: [40100, 47200, 43700, 53100, 49800, 59100, 55600, 62600],
    weekVolume: 62600,
    workoutsThisWeek: 4,
    streakWeeks: 11,
    totalWorkouts: 213,
    weekDays: [1, 0, 1, 1, 0, 1, 0], // mon..sun completed
    prsThisMonth: 5,
    bodyweight: {
      current: 173,
      unit: 'lb',
      delta: 2.5, // change over the shown window
      // last ~12 logged weigh-ins, oldest → newest
      history: [170, 170, 171, 170.5, 171.5, 171, 172, 172, 172.5, 172, 172.5, 173],
      // dated log, newest → oldest
      log: [
        { date: d(0), time: '7:42 AM', w: 173 },
        { date: d(3), time: '7:31 AM', w: 172 },
        { date: d(7), time: '8:05 AM', w: 172.5 },
        { date: d(11), time: '7:20 AM', w: 172 },
        { date: d(15), time: '7:55 AM', w: 171 },
        { date: d(22), time: '8:10 AM', w: 170.5 },
        { date: d(30), time: '7:48 AM', w: 170 },
      ],
    },
    nudge: { ex: 'Bench Press', text: "1RM has climbed 3 sessions straight and you out-rested last week — you're primed for a 265 lb single." },
  };

  // ---- AI Coach mode ----
  const coach = {
    goal: 'Build muscle',
    level: 'Beginner',
    minutes: 45,
    // why this session, in plain founder-to-lifter language
    rationale: "You trained pull 2 days ago and you're newer to the gym, so today is a full-body day built on simple, safe lifts. We keep the reps moderate so you can lock in form before we add weight.",
    session: {
      name: 'Full Body · Day A',
      exercises: [
        { name: 'Goblet Squat', sets: 3, reps: 8, target: 35,
          cue: 'Sit down between your heels, chest tall. Drive through the floor.',
          why: 'The easiest way to learn the squat pattern — it teaches depth and bracing without a barbell on your back.' },
        { name: 'Dumbbell Bench Press', sets: 3, reps: 8, target: 40,
          cue: 'Lower to mid-chest, elbows ~45°. Press up and slightly together.',
          why: 'Builds chest, shoulders and triceps. Dumbbells let each arm work evenly and are gentle on the shoulders.' },
        { name: 'Lat Pulldown', sets: 3, reps: 10, target: 75,
          cue: 'Lead with the elbows, pull the bar to your collarbone. Slow on the way up.',
          why: 'Trains the back and biceps and grooves the pull-up motion before you can do full pull-ups.' },
        { name: 'Dumbbell Shoulder Press', sets: 2, reps: 10, target: 25,
          cue: 'Brace your core, press straight overhead. Don\u2019t let your back arch.',
          why: 'Rounds out the shoulders and adds pressing volume after the bench has pre-fatigued them.' },
        { name: 'Plank', sets: 3, reps: 30, unit: 's', target: null,
          cue: 'Squeeze glutes, ribs down, straight line head to heels.',
          why: 'A safe, joint-friendly way to build the deep core strength every other lift relies on.' },
      ],
    },
    faqs: [
      { q: 'How heavy should I lift?',
        a: 'Pick a weight where the last 2 reps feel genuinely hard but your form holds. If a set feels easy all the way through, nudge the weight up a little next time.' },
      { q: "What's progressive overload?",
        a: 'Doing a little more over time — one more rep, a touch more weight, better control. It\u2019s the engine behind every result, and Physique tracks it for you automatically.' },
      { q: 'Something hurts — what should I do?',
        a: 'Sharp or joint pain means stop that movement. A working-muscle burn is normal and expected. Tap the \u00b7\u00b7\u00b7 on any exercise and I\u2019ll swap in a gentler variation.' },
      { q: 'How many days a week?',
        a: 'Three full-body days with a rest day between is plenty as a beginner — it\u2019s enough to grow without burning out. I\u2019ll space them for you across the week.' },
    ],
  };

  window.PQ = { exercises, activeWorkout, folders, history, progress, coach, today };
})();
