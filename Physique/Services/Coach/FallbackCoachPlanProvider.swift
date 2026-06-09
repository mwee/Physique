import Foundation

/// Deterministic, offline plan generator. Runs whenever the proxy isn't configured or the
/// LLM call fails, so the coach flow never dead-ends. No network.
struct FallbackCoachPlanProvider: CoachPlanProvider {
    func generate(_ request: CoachPlanRequest) async throws -> CoachPlanDraft {
        let scheme = RepScheme.forGoal(request.goal)
        let split = Split.forDays(request.daysPerWeek)

        // Catalog filtered to what the user can actually perform.
        let allowed = Set(request.equipment)
        let usable = request.catalog.filter { allowed.isEmpty || allowed.contains($0.equipment) }

        let days = split.days.enumerated().map { index, focus -> DraftDay in
            let picks = pickExercises(for: focus, from: usable)
            let exercises = picks.enumerated().map { exIndex, cat -> DraftExercise in
                let timed = cat.muscleGroup == .core
                let weight = targetWeight(for: cat, maxes: request.maxes, scheme: scheme, unit: request.unit)
                return DraftExercise(
                    exerciseId: cat.id,
                    name: cat.name,
                    sets: scheme.sets,
                    reps: timed ? 40 : scheme.reps,
                    repsUnit: timed ? "s" : "",
                    targetWeight: timed ? nil : weight,
                    cue: Self.cues[cat.id] ?? "Move with control and keep your form tight.",
                    why: Self.whys[cat.id] ?? "A reliable \(cat.muscleGroup.rawValue.lowercased()) builder that fits today's focus."
                )
            }
            let letter = String(UnicodeScalar(65 + index)!) // A, B, C…
            return DraftDay(
                name: "Day \(letter) · \(focus.title)",
                focus: focus.title,
                rationale: focus.rationale(goal: request.goal),
                exercises: exercises
            )
        }.filter { !$0.exercises.isEmpty }

        return CoachPlanDraft(
            title: "\(request.daysPerWeek)-Day \(split.title)",
            summary: "A \(request.daysPerWeek)-day \(split.title.lowercased()) plan tuned for \(request.goal.lowercased()). "
                + "We keep the movements simple and progress them as you log sessions.",
            days: days
        )
    }

    // MARK: - Exercise selection

    private func pickExercises(for focus: Focus, from catalog: [CatalogExercise]) -> [CatalogExercise] {
        var result: [CatalogExercise] = []
        for group in focus.muscleGroups {
            // Deterministic: first catalog match for this group not already chosen.
            if let pick = catalog.first(where: { cat in
                cat.muscleGroup == group && !result.contains(where: { $0.id == cat.id })
            }) {
                result.append(pick)
            }
        }
        // Backfill from any usable exercise so a day is never empty.
        if result.count < 3 {
            for cat in catalog where !result.contains(where: { $0.id == cat.id }) {
                result.append(cat)
                if result.count >= 4 { break }
            }
        }
        return Array(result.prefix(5))
    }

    private func targetWeight(for cat: CatalogExercise, maxes: [String: Double], scheme: RepScheme, unit: WeightUnit) -> Double? {
        guard let oneRM = maxes[cat.id], oneRM > 0 else { return nil }
        return WeightFormatter.roundToPlate(oneRM * scheme.intensity, unit: unit)
    }

    // MARK: - Schemes & splits

    private struct RepScheme {
        let sets: Int
        let reps: Int
        let intensity: Double // fraction of 1RM for target weight

        static func forGoal(_ goal: String) -> RepScheme {
            switch goal {
            case "Get stronger": return RepScheme(sets: 5, reps: 5, intensity: 0.82)
            case "Build muscle": return RepScheme(sets: 4, reps: 10, intensity: 0.70)
            case "Lose fat": return RepScheme(sets: 3, reps: 12, intensity: 0.65)
            default: return RepScheme(sets: 3, reps: 10, intensity: 0.68) // Stay healthy
            }
        }
    }

    private enum Focus {
        case fullBody, push, pull, legs, upper, lower

        var title: String {
            switch self {
            case .fullBody: "Full Body"
            case .push: "Push"
            case .pull: "Pull"
            case .legs: "Legs"
            case .upper: "Upper Body"
            case .lower: "Lower Body"
            }
        }

        var muscleGroups: [MuscleGroup] {
            switch self {
            case .fullBody: [.legs, .chest, .back, .shoulders, .core]
            case .push: [.chest, .shoulders, .arms]
            case .pull: [.back, .back, .arms]
            case .legs: [.legs, .legs, .core]
            case .upper: [.chest, .back, .shoulders, .arms]
            case .lower: [.legs, .legs, .core]
            }
        }

        func rationale(goal: String) -> String {
            "\(title) day — built to train the right muscles for \(goal.lowercased()) while keeping the movements approachable."
        }
    }

    private struct Split {
        let title: String
        let days: [Focus]

        static func forDays(_ n: Int) -> Split {
            switch n {
            case ...2: return Split(title: "Full Body", days: Array(repeating: .fullBody, count: max(1, n)))
            case 3: return Split(title: "Push/Pull/Legs", days: [.push, .pull, .legs])
            case 4: return Split(title: "Upper/Lower", days: [.upper, .lower, .upper, .lower])
            case 5: return Split(title: "Push/Pull/Legs", days: [.push, .pull, .legs, .upper, .lower])
            default: return Split(title: "Push/Pull/Legs", days: [.push, .pull, .legs, .push, .pull, .legs])
            }
        }
    }

    // MARK: - Coaching copy (reused tone from the original CoachService mock)

    private static let cues: [String: String] = [
        "squat": "Sit down between your heels, chest tall. Drive through the floor.",
        "bench": "Lower to mid-chest, elbows ~45°. Press up and slightly together.",
        "deadlift": "Brace hard, push the floor away. Keep the bar close to your shins.",
        "ohp": "Brace your core, press straight overhead. Don't let your back arch.",
        "row": "Lead with the elbows, squeeze the back. Don't yank with the lower back.",
        "pullup": "Pull your chest to the bar, control the descent.",
        "lat": "Lead with the elbows, pull the bar to your collarbone. Slow on the way up.",
        "curl": "Keep your elbows pinned, no swinging. Squeeze at the top.",
    ]

    private static let whys: [String: String] = [
        "squat": "The foundation of lower-body strength — it trains your quads, glutes and core all at once.",
        "bench": "Builds chest, shoulders and triceps and is the simplest way to track pressing strength.",
        "deadlift": "A full-body pull that builds your back, glutes and grip like nothing else.",
        "ohp": "Rounds out the shoulders and adds overhead pressing strength.",
        "row": "Balances all that pressing and builds a strong, healthy back.",
        "pullup": "The gold-standard back and biceps builder using just your bodyweight.",
        "lat": "Trains the back and biceps and grooves the pull-up motion.",
        "curl": "Direct arm work to round out the upper body and add size.",
    ]
}
