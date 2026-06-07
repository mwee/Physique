/* PHYSIQUE — Template library: built-in programs (window.TPL)
   Each program is a percentage / training-max scheme that turns a 1RM into a
   full plan. `basis`:
     'tm'  → working weights are a % of a Training Max (tmPct of 1RM)
     '1rm' → working weights are a % of your 1RM directly
   `layout`:
     'table'    → blocks render as a grid (columns = sets at varied weights)
     'straight' → blocks render as stacked rows (N × reps at one weight)
*/
(function () {
  const lifts = {
    squat:    { name: 'Back Squat',      short: 'SQ' },
    bench:    { name: 'Bench Press',     short: 'BN' },
    deadlift: { name: 'Deadlift',        short: 'DL' },
    ohp:      { name: 'Overhead Press',  short: 'OHP' },
    row:      { name: 'Barbell Row',     short: 'ROW' },
  };

  // Seed maxes per unit (clean plate-friendly numbers)
  const defaults = {
    kg: { squat: 160, bench: 120, deadlift: 182.5, ohp: 70, row: 110 },
    lb: { squat: 355, bench: 265, deadlift: 405,   ohp: 155, row: 245 },
  };

  const categories = ['All', 'Strength', 'Powerlifting', 'Hypertrophy', 'Beginner'];

  const programs = [
    {
      id: '531bbb',
      name: '5/3/1 Boring But Big',
      author: 'Jim Wendler',
      glyph: '5·3·1',
      featured: true,
      tags: ['Strength', 'Hypertrophy'],
      days: '4 days / week',
      cycle: '4-week wave',
      basis: 'tm', usesTM: true, layout: 'table',
      waved: true, useWeekBlock: true, cycleWeeks: 4,
      weekNames: ['Week 1 · 5s', 'Week 2 · 3s', 'Week 3 · 5/3/1', 'Week 4 · Deload'],
      split: [
        { name: 'Squat day',    ids: ['squat'] },
        { name: 'Bench day',    ids: ['bench'] },
        { name: 'Deadlift day', ids: ['deadlift'] },
        { name: 'Press day',    ids: ['ohp'] },
      ],
      lifts: ['squat', 'bench', 'deadlift', 'ohp'],
      blurb: "Wendler's classic. You train at a conservative training max — 90% of your true 1RM — so progress is slow, steady and almost impossible to stall. Each week ramps to a single rep-out (AMRAP) set, then 5×10 of the same lift packs on size.",
      setHeads: ['Set 1', 'Set 2', 'Top set'],
      blocks: [
        { label: 'Week 1', sub: '5 / 5 / 5+', sets: [{ p: 0.65, r: 5 }, { p: 0.75, r: 5 }, { p: 0.85, r: 5, amrap: true }] },
        { label: 'Week 2', sub: '3 / 3 / 3+', sets: [{ p: 0.70, r: 3 }, { p: 0.80, r: 3 }, { p: 0.90, r: 3, amrap: true }] },
        { label: 'Week 3', sub: '5 / 3 / 1+', sets: [{ p: 0.75, r: 5 }, { p: 0.85, r: 3 }, { p: 0.95, r: 1, amrap: true }] },
        { label: 'Week 4', sub: 'Deload',    sets: [{ p: 0.40, r: 5 }, { p: 0.50, r: 5 }, { p: 0.60, r: 5 }] },
      ],
      warmup: { sets: [{ p: 0.40, r: 5 }, { p: 0.50, r: 5 }, { p: 0.60, r: 3 }] },
      supplemental: { label: 'Boring But Big', detail: '5 × 10', p: 0.50 },
      progressNote: 'After each cycle, bump the training max: +2.5 kg / 5 lb on presses, +5 kg / 10 lb on squat & deadlift.',
    },
    {
      id: 'gzclp',
      name: 'GZCLP',
      author: 'Cody Lefever (GZCL)',
      glyph: 'GZ',
      tags: ['Beginner', 'Strength'],
      days: '3–4 days / week',
      cycle: 'Linear',
      basis: '1rm', usesTM: false, layout: 'straight',
      cycleWeeks: 1,
      split: [
        { name: 'Workout A1', sub: 'Squat · Bench',    items: [{ id: 'squat', b: 0 }, { id: 'bench', b: 1 }] },
        { name: 'Workout B1', sub: 'Press · Deadlift', items: [{ id: 'ohp', b: 0 }, { id: 'deadlift', b: 1 }] },
        { name: 'Workout A2', sub: 'Bench · Squat',    items: [{ id: 'bench', b: 0 }, { id: 'squat', b: 1 }] },
        { name: 'Workout B2', sub: 'Deadlift · Press', items: [{ id: 'deadlift', b: 0 }, { id: 'ohp', b: 1 }] },
      ],
      lifts: ['squat', 'bench', 'deadlift', 'ohp'],
      blurb: "The GZCL method as a beginner linear progression. Every main lift is run as a heavy T1 (5×3, last set for max reps) and a volume T2 (3×10). Add weight every session until you stall, then drop the rep target and keep climbing.",
      blocks: [
        { label: 'As T1', sub: 'Heavy · main', straight: { count: 5, r: 3, amrap: true, p: 0.85 } },
        { label: 'As T2', sub: 'Volume',       straight: { count: 3, r: 10, p: 0.65 } },
      ],
      note: 'Starting weights are suggested from your 1RM — adjust if a set feels off. A T3 accessory (3×15+) rounds out each day.',
      progressNote: 'T1: +2.5 kg / 5 lb each session. T2: +2.5 kg / 5 lb once you complete every rep.',
    },
    {
      id: 'texas',
      name: 'Texas Method',
      author: 'Glenn Pendlay',
      glyph: 'TX',
      tags: ['Strength'],
      days: '3 days / week',
      cycle: 'Weekly',
      basis: '1rm', usesTM: false, layout: 'straight',
      cycleWeeks: 1,
      split: [
        { name: 'Monday',    sub: 'Volume',    b: 0, ids: ['squat', 'bench'] },
        { name: 'Wednesday', sub: 'Recovery',  b: 1, ids: ['squat', 'ohp'] },
        { name: 'Friday',    sub: 'Intensity', b: 2, ids: ['squat', 'bench', 'deadlift'] },
      ],
      lifts: ['squat', 'bench', 'deadlift', 'ohp'],
      blurb: "A weekly intensity wave for lifters past their newbie gains. Monday is heavy volume, Wednesday is a lighter recovery day, and Friday you set a new 5-rep record. The week as a whole drives one PR every Friday.",
      blocks: [
        { label: 'Mon', sub: 'Volume',    straight: { count: 5, r: 5, p: 0.80 } },
        { label: 'Wed', sub: 'Recovery',  straight: { count: 2, r: 5, p: 0.65 } },
        { label: 'Fri', sub: 'Intensity', straight: { count: 1, r: 5, p: 0.87, pr: true } },
      ],
      note: "Friday's single set of 5 is a rep-max attempt — beat it and Monday's volume scales up with you.",
      progressNote: 'Each week, push Friday for a new 5RM, then nudge Monday’s volume weight up to match.',
    },
    {
      id: 'madcow',
      name: 'Madcow 5×5',
      author: 'Bill Starr (adapted)',
      glyph: 'MC',
      tags: ['Strength'],
      days: '3 days / week',
      cycle: 'Weekly ramp',
      basis: '1rm', usesTM: false, layout: 'table',
      waved: true, weekScale: 'mult', cycleWeeks: 4,
      split: [
        { name: 'Monday',    sub: 'Medium', b: 0, ids: ['squat', 'bench', 'row'] },
        { name: 'Wednesday', sub: 'Light',  b: 0, light: true, ids: ['squat', 'ohp', 'deadlift'] },
        { name: 'Friday',    sub: 'Heavy',  b: 0, ids: ['squat', 'bench', 'row'] },
      ],
      lifts: ['squat', 'bench', 'deadlift', 'ohp', 'row'],
      blurb: "The intermediate 5×5. Each session ramps across five sets to one heavy top set of five, and the whole ladder climbs ~2.5% every week. A measured, predictable way to keep adding weight long after linear progression dies.",
      setHeads: ['Set 1', 'Set 2', 'Set 3', 'Set 4', 'Top set'],
      blocks: [
        { label: 'Ramp', sub: '5 × 5 ramping to a top set', sets: [{ p: 0.425, r: 5 }, { p: 0.53, r: 5 }, { p: 0.638, r: 5 }, { p: 0.744, r: 5 }, { p: 0.85, r: 5, top: true }] },
      ],
      progressNote: 'Add ~2.5% to your top set each week. Friday is a heavier triple / single PR day.',
    },
    {
      id: 'smolovjr',
      name: 'Smolov Jr',
      author: 'Sergey Smolov',
      glyph: 'SJr',
      tags: ['Powerlifting'],
      days: '4 days / week',
      cycle: '3-week block',
      basis: '1rm', usesTM: false, layout: 'straight', single: true,
      waved: true, weekScale: 'add', cycleWeeks: 3,
      split: [
        { name: 'Monday',    sub: '6×6',  b: 0, ids: ['bench'] },
        { name: 'Wednesday', sub: '7×5',  b: 1, ids: ['bench'] },
        { name: 'Friday',    sub: '8×4',  b: 2, ids: ['bench'] },
        { name: 'Saturday',  sub: '10×3', b: 3, ids: ['bench'] },
      ],
      lifts: ['bench'],
      blurb: "A brutal three-week specialization block, usually run on the bench press. Four sessions a week, each a different volume-and-intensity prescription off your 1RM. Heavy, frequent, and famous for adding 10–15 kg to a stalled bench.",
      blocks: [
        { label: 'Mon', sub: 'Volume',    straight: { count: 6, r: 6, p: 0.70 } },
        { label: 'Wed', sub: '',          straight: { count: 7, r: 5, p: 0.75 } },
        { label: 'Fri', sub: '',          straight: { count: 8, r: 4, p: 0.80 } },
        { label: 'Sat', sub: 'Intensity', straight: { count: 10, r: 3, p: 0.85 } },
      ],
      note: 'Pick one lift to specialise — bench is the classic choice.',
      progressNote: 'Add 2.5 kg / 5 lb to every set each week of the block, then retest your 1RM.',
    },
  ];

  window.TPL = { lifts, defaults, categories, programs };
})();
