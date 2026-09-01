import Foundation
import SwiftData

enum WorkoutEngine {
    /// Check if this set is a personal record (weight > previous best at same or fewer reps)
    static func isPR(weight: Double, reps: Int, exercise: Exercise?) -> Bool {
        guard let exercise, let bestWeight = exercise.bestWeight else { return false }
        return weight > bestWeight
    }

    /// Calculate total volume for completed working sets
    static func calculateVolume(exercises: [ActiveExercise]) -> Double {
        exercises.reduce(0) { total, ex in
            total + ex.sets.filter { $0.isDone && !$0.type.isWarmup }.reduce(0) { $0 + $1.weight * Double($1.reps) }
        }
    }

    /// Count completed sets
    static func completedSets(exercises: [ActiveExercise]) -> Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isDone).count }
    }

    /// Count PRs
    static func prCount(exercises: [ActiveExercise]) -> Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isPR).count }
    }

    /// Update exercise records after completing a workout
    static func updateExerciseRecords(exercise: Exercise, sets: [ActiveSet], context: ModelContext) {
        let workingSets = sets.filter { $0.isDone && !$0.type.isWarmup }
        guard !workingSets.isEmpty else { return }

        // Best weight from this session
        let maxWeight = workingSets.map(\.weight).max() ?? 0

        // Best e1RM from this session
        let maxE1RM = workingSets.map { E1RMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0

        // Session volume
        let sessionVolume = workingSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }

        // Update exercise cached fields
        if maxE1RM > (exercise.bestEstimated1RM ?? 0) {
            let oldE1RM = exercise.bestEstimated1RM ?? maxE1RM
            exercise.e1rmDelta = maxE1RM - oldE1RM
            exercise.bestEstimated1RM = maxE1RM
        }
        if maxWeight > (exercise.bestWeight ?? 0) {
            exercise.bestWeight = maxWeight
        }

        // Append to e1rm history (keep last 8 points); high-rep-only sessions
        // produce no estimate and are skipped rather than logged as 0.
        if maxE1RM > 0 {
            exercise.e1rmHistory.append(maxE1RM)
            if exercise.e1rmHistory.count > 8 {
                exercise.e1rmHistory = Array(exercise.e1rmHistory.suffix(8))
            }
        }
    }

    /// Save a completed workout to SwiftData
    static func saveWorkout(
        name: String,
        exercises: [ActiveExercise],
        duration: TimeInterval,
        context: ModelContext
    ) -> WorkoutSession {
        let volume = calculateVolume(exercises: exercises)
        let sets = completedSets(exercises: exercises)
        let prs = prCount(exercises: exercises)

        let session = WorkoutSession(
            name: name,
            duration: duration,
            totalVolume: volume,
            totalSets: sets,
            prCount: prs
        )
        context.insert(session)

        for (index, activeEx) in exercises.enumerated() {
            let sessionEx = SessionExercise(
                orderIndex: index,
                exerciseName: activeEx.name,
                exercise: activeEx.exercise
            )
            sessionEx.session = session

            for (setIndex, activeSet) in activeEx.sets.enumerated() where activeSet.isDone {
                let set = ExerciseSet(
                    orderIndex: setIndex,
                    setType: activeSet.type,
                    weight: activeSet.weight,
                    reps: activeSet.reps,
                    isCompleted: true,
                    isPersonalRecord: activeSet.isPR
                )
                set.sessionExercise = sessionEx
                context.insert(set)
            }

            context.insert(sessionEx)

            // Update exercise records
            if let exercise = activeEx.exercise {
                updateExerciseRecords(exercise: exercise, sets: activeEx.sets, context: context)
            }
        }

        try? context.save()
        return session
    }
}

// MARK: - Active Workout Data Structures (in-memory, not persisted)

struct ActiveExercise: Identifiable {
    let id = UUID()
    var exId: String
    var name: String
    var exercise: Exercise?
    var note: String?
    var cue: String?
    var sets: [ActiveSet]
}

struct ActiveSet: Identifiable {
    let id = UUID()
    var type: SetType
    var prevWeight: Double?
    var prevReps: Int?
    var weight: Double
    var reps: Int
    var isDone: Bool = false
    var isPR: Bool = false

    var previousDisplay: String {
        guard let pw = prevWeight, let pr = prevReps else { return "\u{2014}" }
        return "\(WeightFormatter.format(pw)) \u{00D7} \(pr)"
    }
}
