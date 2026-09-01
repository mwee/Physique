import Foundation

/// The built-in exercise catalog: the movements you actually find in a
/// commercial gym — barbell, dumbbell, machine, cable and bodyweight.
/// `SeedDataService` inserts any entry missing from the store, and the
/// program engine falls back to it for display names.
enum ExerciseCatalog {

    struct Entry {
        let id: String
        let name: String
        let muscleGroup: MuscleGroup
        let equipment: ExerciseType
        var lowerBody: Bool = false
    }

    static let entries: [Entry] = [
        // MARK: Barbell
        Entry(id: "squat", name: "Back Squat", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "front_squat", name: "Front Squat", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "bench", name: "Bench Press", muscleGroup: .chest, equipment: .barbell),
        Entry(id: "incline_bench", name: "Incline Bench Press", muscleGroup: .chest, equipment: .barbell),
        Entry(id: "close_grip_bench", name: "Close-Grip Bench Press", muscleGroup: .arms, equipment: .barbell),
        Entry(id: "deadlift", name: "Deadlift", muscleGroup: .back, equipment: .barbell, lowerBody: true),
        Entry(id: "sumo_deadlift", name: "Sumo Deadlift", muscleGroup: .back, equipment: .barbell, lowerBody: true),
        Entry(id: "rdl", name: "Romanian Deadlift", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "ohp", name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
        Entry(id: "push_press", name: "Push Press", muscleGroup: .shoulders, equipment: .barbell),
        Entry(id: "row", name: "Barbell Row", muscleGroup: .back, equipment: .barbell),
        Entry(id: "hip_thrust", name: "Barbell Hip Thrust", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "good_morning", name: "Good Morning", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "bb_lunge", name: "Barbell Lunge", muscleGroup: .legs, equipment: .barbell, lowerBody: true),
        Entry(id: "bb_curl", name: "Barbell Curl", muscleGroup: .arms, equipment: .barbell),
        Entry(id: "bb_shrug", name: "Barbell Shrug", muscleGroup: .back, equipment: .barbell),

        // MARK: Dumbbell
        Entry(id: "db_bench", name: "Dumbbell Bench Press", muscleGroup: .chest, equipment: .dumbbell),
        Entry(id: "db_incline_bench", name: "Incline Dumbbell Press", muscleGroup: .chest, equipment: .dumbbell),
        Entry(id: "db_fly", name: "Dumbbell Fly", muscleGroup: .chest, equipment: .dumbbell),
        Entry(id: "db_shoulder_press", name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipment: .dumbbell),
        Entry(id: "lateral_raise", name: "Lateral Raise", muscleGroup: .shoulders, equipment: .dumbbell),
        Entry(id: "rear_delt_fly", name: "Rear Delt Fly", muscleGroup: .shoulders, equipment: .dumbbell),
        Entry(id: "db_row", name: "One-Arm Dumbbell Row", muscleGroup: .back, equipment: .dumbbell),
        Entry(id: "db_shrug", name: "Dumbbell Shrug", muscleGroup: .back, equipment: .dumbbell),
        Entry(id: "curl", name: "Dumbbell Curl", muscleGroup: .arms, equipment: .dumbbell),
        Entry(id: "hammer_curl", name: "Hammer Curl", muscleGroup: .arms, equipment: .dumbbell),
        Entry(id: "db_tricep_ext", name: "Overhead Tricep Extension", muscleGroup: .arms, equipment: .dumbbell),
        Entry(id: "skull_crusher", name: "Skull Crusher", muscleGroup: .arms, equipment: .dumbbell),
        Entry(id: "goblet_squat", name: "Goblet Squat", muscleGroup: .legs, equipment: .dumbbell, lowerBody: true),
        Entry(id: "db_lunge", name: "Dumbbell Lunge", muscleGroup: .legs, equipment: .dumbbell, lowerBody: true),
        Entry(id: "bulgarian_split_squat", name: "Bulgarian Split Squat", muscleGroup: .legs, equipment: .dumbbell, lowerBody: true),
        Entry(id: "db_rdl", name: "Dumbbell Romanian Deadlift", muscleGroup: .legs, equipment: .dumbbell, lowerBody: true),
        Entry(id: "db_step_up", name: "Dumbbell Step-Up", muscleGroup: .legs, equipment: .dumbbell, lowerBody: true),

        // MARK: Machine
        Entry(id: "lat", name: "Lat Pulldown", muscleGroup: .back, equipment: .machine),
        Entry(id: "leg_press", name: "Leg Press", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "hack_squat", name: "Hack Squat", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "leg_extension", name: "Leg Extension", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "leg_curl", name: "Leg Curl", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "calf_raise", name: "Standing Calf Raise", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "hip_abduction", name: "Hip Abduction", muscleGroup: .legs, equipment: .machine, lowerBody: true),
        Entry(id: "chest_press", name: "Machine Chest Press", muscleGroup: .chest, equipment: .machine),
        Entry(id: "pec_deck", name: "Pec Deck", muscleGroup: .chest, equipment: .machine),
        Entry(id: "machine_shoulder_press", name: "Machine Shoulder Press", muscleGroup: .shoulders, equipment: .machine),
        Entry(id: "machine_row", name: "Machine Row", muscleGroup: .back, equipment: .machine),
        Entry(id: "preacher_curl", name: "Preacher Curl", muscleGroup: .arms, equipment: .machine),
        Entry(id: "assisted_pullup", name: "Assisted Pull Up", muscleGroup: .back, equipment: .machine),
        Entry(id: "smith_squat", name: "Smith Machine Squat", muscleGroup: .legs, equipment: .machine, lowerBody: true),

        // MARK: Cable
        Entry(id: "seated_row", name: "Seated Cable Row", muscleGroup: .back, equipment: .cable),
        Entry(id: "straight_arm_pulldown", name: "Straight-Arm Pulldown", muscleGroup: .back, equipment: .cable),
        Entry(id: "face_pull", name: "Face Pull", muscleGroup: .shoulders, equipment: .cable),
        Entry(id: "cable_lateral_raise", name: "Cable Lateral Raise", muscleGroup: .shoulders, equipment: .cable),
        Entry(id: "cable_fly", name: "Cable Fly", muscleGroup: .chest, equipment: .cable),
        Entry(id: "tricep_pushdown", name: "Tricep Pushdown", muscleGroup: .arms, equipment: .cable),
        Entry(id: "cable_curl", name: "Cable Curl", muscleGroup: .arms, equipment: .cable),
        Entry(id: "cable_crunch", name: "Cable Crunch", muscleGroup: .core, equipment: .cable),
        Entry(id: "cable_pull_through", name: "Cable Pull-Through", muscleGroup: .legs, equipment: .cable, lowerBody: true),

        // MARK: Bodyweight
        Entry(id: "pullup", name: "Pull Up", muscleGroup: .back, equipment: .bodyweight),
        Entry(id: "chinup", name: "Chin Up", muscleGroup: .back, equipment: .bodyweight),
        Entry(id: "dip", name: "Dip", muscleGroup: .chest, equipment: .bodyweight),
        Entry(id: "pushup", name: "Push Up", muscleGroup: .chest, equipment: .bodyweight),
        Entry(id: "inverted_row", name: "Inverted Row", muscleGroup: .back, equipment: .bodyweight),
        Entry(id: "back_extension", name: "Back Extension", muscleGroup: .back, equipment: .bodyweight),
        Entry(id: "plank", name: "Plank", muscleGroup: .core, equipment: .bodyweight),
        Entry(id: "hanging_leg_raise", name: "Hanging Leg Raise", muscleGroup: .core, equipment: .bodyweight),
        Entry(id: "ab_wheel", name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .bodyweight),
    ]

    private static let byId: [String: Entry] = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

    static func entry(for id: String) -> Entry? { byId[id] }

    /// Display name for a lift id, checking the program lift table first,
    /// then the catalog, then a readable fallback for unknown slugs.
    static func displayName(for id: String) -> String {
        if let lift = BuiltInPrograms.lifts[id] { return lift.name }
        if let entry = byId[id] { return entry.name }
        return id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Short label for tight spaces ("SQ", "DL", or the first word).
    static func shortName(for id: String) -> String {
        if let lift = BuiltInPrograms.lifts[id] { return lift.short }
        let name = displayName(for: id)
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    /// Lower-body lifts get the bigger training-max bump between blocks.
    static func isLowerBody(_ id: String) -> Bool {
        byId[id]?.lowerBody ?? false
    }
}
