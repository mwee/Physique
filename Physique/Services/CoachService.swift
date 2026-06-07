import Foundation

struct CoachSession {
    let name: String
    let exercises: [CoachExercise]
}

struct CoachExercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int
    var unit: String = ""
    let target: Double?
    let cue: String
    let why: String
}

@Observable
final class CoachService {
    var isLoading = false
    var currentSession: CoachSession?
    var goal: String = "Build muscle"
    var level: String = "Beginner"
    var minutes: Int = 45
    var rationale: String = ""

    // FAQ tracking
    var askedFAQs: Set<Int> = []
    var chatMessages: [(isUser: Bool, text: String)] = []

    func generateSession() async {
        isLoading = true

        // Use fallback data for now (API integration comes later)
        try? await Task.sleep(for: .seconds(1.2))

        rationale = "You trained pull 2 days ago and you're newer to the gym, so today is a full-body day built on simple, safe lifts. We keep the reps moderate so you can lock in form before we add weight."

        currentSession = CoachSession(
            name: "Full Body \u{00B7} Day A",
            exercises: [
                CoachExercise(name: "Goblet Squat", sets: 3, reps: 8, target: 35, cue: "Sit down between your heels, chest tall. Drive through the floor.", why: "The easiest way to learn the squat pattern \u{2014} it teaches depth and bracing without a barbell on your back."),
                CoachExercise(name: "Dumbbell Bench Press", sets: 3, reps: 8, target: 40, cue: "Lower to mid-chest, elbows ~45\u{00B0}. Press up and slightly together.", why: "Builds chest, shoulders and triceps. Dumbbells let each arm work evenly and are gentle on the shoulders."),
                CoachExercise(name: "Lat Pulldown", sets: 3, reps: 10, target: 75, cue: "Lead with the elbows, pull the bar to your collarbone. Slow on the way up.", why: "Trains the back and biceps and grooves the pull-up motion before you can do full pull-ups."),
                CoachExercise(name: "Dumbbell Shoulder Press", sets: 2, reps: 10, target: 25, cue: "Brace your core, press straight overhead. Don\u{2019}t let your back arch.", why: "Rounds out the shoulders and adds pressing volume after the bench has pre-fatigued them."),
                CoachExercise(name: "Plank", sets: 3, reps: 30, unit: "s", target: nil, cue: "Squeeze glutes, ribs down, straight line head to heels.", why: "A safe, joint-friendly way to build the deep core strength every other lift relies on."),
            ]
        )

        isLoading = false
    }

    static let faqs: [(question: String, answer: String)] = [
        ("How heavy should I lift?", "Pick a weight where the last 2 reps feel genuinely hard but your form holds. If a set feels easy all the way through, nudge the weight up a little next time."),
        ("What\u{2019}s progressive overload?", "Doing a little more over time \u{2014} one more rep, a touch more weight, better control. It\u{2019}s the engine behind every result, and Physique tracks it for you automatically."),
        ("Something hurts \u{2014} what should I do?", "Sharp or joint pain means stop that movement. A working-muscle burn is normal and expected. Tap the \u{00B7}\u{00B7}\u{00B7} on any exercise and I\u{2019}ll swap in a gentler variation."),
        ("How many days a week?", "Three full-body days with a rest day between is plenty as a beginner \u{2014} it\u{2019}s enough to grow without burning out. I\u{2019}ll space them for you across the week."),
    ]

    func askFAQ(index: Int) {
        guard !askedFAQs.contains(index) else { return }
        askedFAQs.insert(index)
        let faq = Self.faqs[index]
        chatMessages.append((isUser: true, text: faq.question))
        chatMessages.append((isUser: false, text: faq.answer))
    }

    func askFreeText(_ text: String) {
        chatMessages.append((isUser: true, text: text))
        // Fallback response
        chatMessages.append((isUser: false, text: "That\u{2019}s a great question. For now, I\u{2019}d suggest sticking with the plan and tracking how it feels \u{2014} we\u{2019}ll adjust as you go."))
    }

    /// Convert the current coach session to ActiveExercise array for the workout
    func sessionToExercises() -> [ActiveExercise] {
        guard let session = currentSession else { return [] }
        return session.exercises.enumerated().map { index, ex in
            let sets = (0..<ex.sets).map { setIdx in
                ActiveSet(
                    type: .working(setIdx + 1),
                    weight: ex.target ?? 0,
                    reps: ex.reps
                )
            }
            return ActiveExercise(
                exId: ex.name.lowercased().replacingOccurrences(of: " ", with: "_"),
                name: ex.name,
                cue: ex.cue,
                sets: sets
            )
        }
    }
}
