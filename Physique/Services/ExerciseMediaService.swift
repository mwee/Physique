import Foundation

/// Demonstration media and form instructions for catalog exercises.
/// Frames and instruction text sourced from the public-domain
/// free-exercise-db (github.com/yuhonas/free-exercise-db).
enum ExerciseMediaService {
    /// Exercise ids that have demonstration frames in the asset catalog.
    private static let idsWithFrames: Set<String> = [
        "deadlift", "bench", "squat", "ohp", "row", "pullup", "curl", "lat",
    ]

    /// Asset names of the demonstration frames (start/end position),
    /// or an empty array if no media exists for this exercise.
    static func frames(for exerciseId: String) -> [String] {
        guard idsWithFrames.contains(exerciseId) else { return [] }
        return ["exercise_\(exerciseId)_0", "exercise_\(exerciseId)_1"]
    }

    /// Step-by-step form instructions, or an empty array if none exist.
    static func instructions(for exerciseId: String) -> [String] {
        instructionsById[exerciseId] ?? []
    }

    private static let instructionsById: [String: [String]] = [
        "deadlift": [
            "Stand in front of a loaded barbell with feet about shoulder width apart.",
            "Keeping your back as straight as possible, bend your knees, bend forward and grasp the bar with a medium overhand grip.",
            "Start the lift by pushing with your legs while bringing your torso upright as you breathe out. At the top, stick your chest out and pull the shoulder blades back.",
            "Return to the start by bending at the knees and leaning the torso forward at the waist, keeping the back straight, until the plates touch the floor.",
        ],
        "bench": [
            "Lie back on a flat bench. Grip the bar at medium width, lift it from the rack and hold it straight over you with arms locked.",
            "Breathe in and lower the bar slowly until it touches your middle chest.",
            "After a brief pause, push the bar back to the starting position as you breathe out, focusing on driving with your chest. Lowering should take about twice as long as raising.",
            "When you're done, place the bar back in the rack.",
        ],
        "squat": [
            "Set the bar on a rack just below shoulder level. Step under it and place the back of your shoulders across it, then lift it off by pushing with your legs.",
            "Step back and stand with feet shoulder width apart, toes slightly pointed out, head up and back straight.",
            "Slowly lower by bending the knees and hips, keeping posture upright, until your thighs go just below parallel. Inhale on the way down — knees should track over your toes.",
            "Drive back up through your heels as you exhale, straightening the legs to return to the start.",
        ],
        "ohp": [
            "Set a barbell at about chest height on a rack. Grip it palms-forward, slightly wider than shoulder width.",
            "Lift the bar to your collarbone, step back, and press it overhead until your arms lock out. Hold at shoulder level slightly in front of your head — this is your start.",
            "Lower the bar slowly to the collarbone as you inhale.",
            "Press back up to lockout as you exhale.",
        ],
        "row": [
            "Hold a barbell with a palms-down grip. Bend your knees slightly and hinge forward at the waist, back straight, until your torso is almost parallel to the floor. Keep your head up.",
            "Keeping the torso stationary, breathe out and pull the barbell to your torso, elbows close to the body. Squeeze the back muscles at the top and hold briefly.",
            "Inhale and slowly lower the barbell back to the start.",
        ],
        "pullup": [
            "Grab the bar with palms facing forward, hands a bit wider than shoulder width.",
            "Hang with arms extended, lean your torso back about 30 degrees and stick your chest out — this is your start.",
            "Pull your torso up until the bar approaches your upper chest, drawing the shoulders and upper arms down and back. Exhale and squeeze your back at the top.",
            "After a second at the top, inhale and lower yourself slowly until your arms are fully extended.",
        ],
        "curl": [
            "Stand up straight with a dumbbell in each hand at arm's length, elbows close to your torso, palms facing forward.",
            "Keeping the upper arms stationary, exhale and curl the weights up to shoulder level while contracting your biceps. Squeeze briefly at the top.",
            "Inhale and slowly lower the dumbbells back to the start.",
        ],
        "lat": [
            "Sit at a pulldown machine with a wide bar attached. Adjust the knee pad to fit your height.",
            "Grab the bar palms-forward, wider than shoulder width. Lean your torso back about 30 degrees and stick your chest out.",
            "As you breathe out, pull the bar down to your upper chest by drawing the shoulders and upper arms down and back. Squeeze your shoulder blades together at the bottom.",
            "Slowly let the bar rise back up until your arms are fully extended and your lats are stretched, inhaling on the way.",
        ],
    ]
}
