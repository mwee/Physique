import Foundation

struct BuiltInPrograms {

    // MARK: - Lift Definitions

    static let lifts: [String: (name: String, short: String)] = [
        "squat":    (name: "Back Squat",      short: "SQ"),
        "bench":    (name: "Bench Press",      short: "BN"),
        "deadlift": (name: "Deadlift",         short: "DL"),
        "ohp":      (name: "Overhead Press",   short: "OHP"),
        "row":      (name: "Barbell Row",      short: "ROW"),
    ]

    // MARK: - Default Maxes

    static let defaults: [WeightUnit: [String: Double]] = [
        .kg: [
            "squat":    160,
            "bench":    120,
            "deadlift": 182.5,
            "ohp":      70,
            "row":      110,
        ],
        .lb: [
            "squat":    355,
            "bench":    265,
            "deadlift": 405,
            "ohp":      155,
            "row":      245,
        ],
    ]

    // MARK: - Categories

    static let categories: [String] = [
        "Strength",
        "Powerlifting",
        "Peaking",
        "Linear Progression",
    ]

    // MARK: - All Programs

    static let programs: [ProgramDefinition] = [
        fiveThreeOneBBB,
        gzclp,
        texasMethod,
        madcow,
        smolovJr,
    ]

    // MARK: - Program Lookup

    static func find(_ id: String) -> ProgramDefinition? {
        programs.first { $0.id == id }
    }

    // MARK: - 5/3/1 Boring But Big

    private static let fiveThreeOneBBB = ProgramDefinition(
        id: "531bbb",
        name: "5/3/1 Boring But Big",
        author: "Jim Wendler",
        glyph: "flame.fill",
        featured: true,
        tags: ["Strength", "Powerlifting"],
        days: "4 days",
        cycle: "4-week wave",
        basis: .trainingMax,
        layout: .table,
        blurb: "The classic 5/3/1 program with Boring But Big supplemental work. Four weekly sessions that wave through three intensity phases plus a deload.",
        cycleWeeks: 4,
        weekNames: ["Week 1 - 5s", "Week 2 - 3s", "Week 3 - 5/3/1", "Week 4 - Deload"],
        split: [
            SplitDay(name: "Squat",    ids: ["squat"]),
            SplitDay(name: "Bench",    ids: ["bench"]),
            SplitDay(name: "Deadlift", ids: ["deadlift"]),
            SplitDay(name: "Press",    ids: ["ohp"]),
        ],
        liftIds: ["squat", "bench", "deadlift", "ohp"],
        blocks: [
            ProgramBlock(label: "Week 1", sub: "5s", sets: [
                ProgramSet(p: 0.65, r: 5),
                ProgramSet(p: 0.75, r: 5),
                ProgramSet(p: 0.85, r: 5, amrap: true),
            ]),
            ProgramBlock(label: "Week 2", sub: "3s", sets: [
                ProgramSet(p: 0.70, r: 3),
                ProgramSet(p: 0.80, r: 3),
                ProgramSet(p: 0.90, r: 3, amrap: true),
            ]),
            ProgramBlock(label: "Week 3", sub: "5/3/1", sets: [
                ProgramSet(p: 0.75, r: 5),
                ProgramSet(p: 0.85, r: 3),
                ProgramSet(p: 0.95, r: 1, amrap: true),
            ]),
            ProgramBlock(label: "Week 4", sub: "Deload", sets: [
                ProgramSet(p: 0.40, r: 5),
                ProgramSet(p: 0.50, r: 5),
                ProgramSet(p: 0.60, r: 5),
            ]),
        ],
        warmup: WarmupConfig(sets: [
            ProgramSet(p: 0.40, r: 5),
            ProgramSet(p: 0.50, r: 5),
            ProgramSet(p: 0.60, r: 3),
        ]),
        supplemental: SupplementalConfig(
            label: "BBB",
            detail: "5\u{00D7}10",
            p: 0.50
        ),
        progressNote: "After completing all 4 weeks, increase training maxes: +5 lb / 2.5 kg for upper body, +10 lb / 5 kg for lower body.",
        setHeads: ["Set 1", "Set 2", "Set 3"],
        waved: true,
        useWeekBlock: true
    )

    // MARK: - GZCLP

    private static let gzclp = ProgramDefinition(
        id: "gzclp",
        name: "GZCLP",
        author: "Cody LeFever",
        glyph: "chart.bar.fill",
        tags: ["Linear Progression", "Strength"],
        days: "3\u{2013}4 days",
        cycle: "Linear",
        basis: .oneRepMax,
        layout: .straight,
        blurb: "A linear progression built on the GZCL tiered framework. Alternates heavy T1 compounds with lighter T2 volume work across four rotating workouts.",
        cycleWeeks: 1,
        split: [
            SplitDay(name: "A1", sub: "Squat / Bench", items: [
                SplitItem(id: "squat", b: 0),
                SplitItem(id: "bench", b: 1),
            ]),
            SplitDay(name: "B1", sub: "OHP / Deadlift", items: [
                SplitItem(id: "ohp",      b: 0),
                SplitItem(id: "deadlift", b: 1),
            ]),
            SplitDay(name: "A2", sub: "Bench / Squat", items: [
                SplitItem(id: "bench", b: 0),
                SplitItem(id: "squat", b: 1),
            ]),
            SplitDay(name: "B2", sub: "Deadlift / OHP", items: [
                SplitItem(id: "deadlift", b: 0),
                SplitItem(id: "ohp",      b: 1),
            ]),
        ],
        liftIds: ["squat", "bench", "deadlift", "ohp"],
        blocks: [
            ProgramBlock(label: "T1", sub: "Heavy", straight: StraightConfig(
                count: 5, r: 3, p: 0.85, amrap: true
            )),
            ProgramBlock(label: "T2", sub: "Volume", straight: StraightConfig(
                count: 3, r: 10, p: 0.65
            )),
        ],
        progressNote: "Add weight each session: +5 lb / 2.5 kg per lift. If you fail to hit the minimum reps, move to the next rep scheme."
    )

    // MARK: - Texas Method

    private static let texasMethod = ProgramDefinition(
        id: "texas",
        name: "Texas Method",
        author: "Glenn Pendlay / Mark Rippetoe",
        glyph: "star.fill",
        tags: ["Strength"],
        days: "3 days",
        cycle: "Weekly",
        basis: .oneRepMax,
        layout: .straight,
        blurb: "A weekly undulation of volume, recovery, and intensity. Monday is heavy volume, Wednesday is a light recovery day, and Friday targets new PRs.",
        cycleWeeks: 1,
        split: [
            SplitDay(name: "Mon", sub: "Volume",    ids: ["squat", "bench", "deadlift"]),
            SplitDay(name: "Wed", sub: "Recovery",   ids: ["squat", "ohp",   "row"], light: true),
            SplitDay(name: "Fri", sub: "Intensity",  ids: ["squat", "bench", "deadlift"]),
        ],
        liftIds: ["squat", "bench", "deadlift", "ohp", "row"],
        blocks: [
            ProgramBlock(label: "Volume", sub: "Monday", straight: StraightConfig(
                count: 5, r: 5, p: 0.80
            )),
            ProgramBlock(label: "Recovery", sub: "Wednesday", straight: StraightConfig(
                count: 2, r: 5, p: 0.65
            )),
            ProgramBlock(label: "Intensity", sub: "Friday", straight: StraightConfig(
                count: 1, r: 5, p: 0.87, pr: true
            )),
        ],
        progressNote: "Increase intensity day weight by 5 lb / 2.5 kg each week. Adjust volume day to 90% of intensity."
    )

    // MARK: - Madcow 5x5

    private static let madcow = ProgramDefinition(
        id: "madcow",
        name: "Madcow 5\u{00D7}5",
        author: "Bill Starr / Madcow",
        glyph: "arrow.up.right",
        featured: true,
        tags: ["Strength"],
        days: "3 days",
        cycle: "Weekly ramp",
        basis: .oneRepMax,
        layout: .table,
        blurb: "A weekly ramping intermediate program. Each workout ramps up across five sets to a top set, with weight increasing week over week.",
        cycleWeeks: 1,
        split: [
            SplitDay(name: "Mon", sub: "Heavy",      ids: ["squat", "bench", "row"]),
            SplitDay(name: "Wed", sub: "Light",       ids: ["squat", "ohp",   "deadlift"], light: true),
            SplitDay(name: "Fri", sub: "Medium / PR", ids: ["squat", "bench", "row"]),
        ],
        liftIds: ["squat", "bench", "deadlift", "ohp", "row"],
        blocks: [
            ProgramBlock(label: "Ramp", sub: "5 ramping sets", sets: [
                ProgramSet(p: 0.425, r: 5),
                ProgramSet(p: 0.530, r: 5),
                ProgramSet(p: 0.638, r: 5),
                ProgramSet(p: 0.744, r: 5),
                ProgramSet(p: 0.850, r: 5, top: true),
            ]),
        ],
        progressNote: "Increase your top-set weight by ~2.5% each week. The ramping sets scale proportionally.",
        setHeads: ["Set 1", "Set 2", "Set 3", "Set 4", "Set 5"],
        waved: true,
        weekScale: .multiplicative
    )

    // MARK: - Smolov Jr

    private static let smolovJr = ProgramDefinition(
        id: "smolovjr",
        name: "Smolov Jr.",
        author: "Sergey Smolov",
        glyph: "bolt.fill",
        tags: ["Peaking", "Powerlifting"],
        days: "4 days",
        cycle: "3-week",
        basis: .oneRepMax,
        layout: .straight,
        blurb: "A short, aggressive peaking cycle for a single lift. Four sessions per week with escalating volume and intensity over three weeks.",
        cycleWeeks: 3,
        weekNames: ["Week 1", "Week 2", "Week 3"],
        split: [
            SplitDay(name: "Mon", sub: "6\u{00D7}6"),
            SplitDay(name: "Wed", sub: "7\u{00D7}5"),
            SplitDay(name: "Fri", sub: "8\u{00D7}4"),
            SplitDay(name: "Sat", sub: "10\u{00D7}3"),
        ],
        liftIds: ["squat"],
        blocks: [
            ProgramBlock(label: "Day 1", sub: "6\u{00D7}6", straight: StraightConfig(
                count: 6, r: 6, p: 0.70
            )),
            ProgramBlock(label: "Day 2", sub: "7\u{00D7}5", straight: StraightConfig(
                count: 7, r: 5, p: 0.75
            )),
            ProgramBlock(label: "Day 3", sub: "8\u{00D7}4", straight: StraightConfig(
                count: 8, r: 4, p: 0.80
            )),
            ProgramBlock(label: "Day 4", sub: "10\u{00D7}3", straight: StraightConfig(
                count: 10, r: 3, p: 0.85
            )),
        ],
        progressNote: "Add 10 lb / 5 kg to all working weights each week. Test a new max after completing all three weeks.",
        waved: true,
        weekScale: .additive,
        single: true
    )
}
