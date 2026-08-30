import Foundation

/// Derives per-lift 1RM stats from two sources:
/// tested maxes the user logged (`OneRepMaxEntry`) and estimated 1RMs
/// computed from completed working sets in logged sessions (Epley).
enum LiftStatsService {

    struct DatedMax {
        let date: Date
        let value: Double
        let tested: Bool
    }

    struct TopSet: Identifiable {
        var id: String { "\(display)-\(dateLabel)" }
        let display: String   // "295 × 3"
        let dateLabel: String // "Tue" / "Aug 18"
    }

    // MARK: - Matching

    /// A session exercise counts toward a lift when it links to the exercise
    /// with that id, or (for unlinked sessions) its denormalized name matches.
    private static func matches(_ sessionExercise: SessionExercise, liftId: String, liftName: String) -> Bool {
        if let id = sessionExercise.exercise?.id { return id == liftId }
        return sessionExercise.exerciseName.caseInsensitiveCompare(liftName) == .orderedSame
    }

    private static func completedWorkingSets(_ sessionExercise: SessionExercise) -> [ExerciseSet] {
        sessionExercise.sortedSets.filter { $0.isCompleted && !$0.setType.isWarmup && $0.weight > 0 && $0.reps > 0 }
    }

    // MARK: - History

    /// Chronological 1RM history for a lift: every tested entry plus the best
    /// estimated 1RM of each session that trained the lift.
    static func history(
        liftId: String,
        liftName: String,
        entries: [OneRepMaxEntry],
        sessions: [WorkoutSession]
    ) -> [DatedMax] {
        var points: [DatedMax] = entries
            .filter { $0.exerciseId == liftId }
            .map { DatedMax(date: $0.date, value: $0.weight, tested: true) }

        for session in sessions {
            for sessionExercise in session.exercises where matches(sessionExercise, liftId: liftId, liftName: liftName) {
                let bestE1RM = completedWorkingSets(sessionExercise)
                    .map { E1RMCalculator.estimate(weight: $0.weight, reps: $0.reps) }
                    .max() ?? 0
                if bestE1RM > 0 {
                    points.append(DatedMax(date: session.date, value: bestE1RM, tested: false))
                }
            }
        }

        return points.sorted { $0.date < $1.date }
    }

    /// The lift's current 1RM: the most recent data point (tested or estimated).
    static func currentMax(in history: [DatedMax]) -> Double? {
        history.last?.value
    }

    /// True when the latest point is the all-time high.
    static func isAtPeak(_ history: [DatedMax]) -> Bool {
        guard let last = history.last?.value,
              let peak = history.map(\.value).max() else { return false }
        return last >= peak
    }

    // MARK: - Recent top sets

    /// The heaviest completed working set from each of the most recent
    /// sessions that trained this lift.
    static func recentTopSets(
        liftId: String,
        liftName: String,
        sessions: [WorkoutSession],
        limit: Int = 3
    ) -> [TopSet] {
        var result: [TopSet] = []
        // Sessions are expected newest-first from the callers' sorted queries.
        for session in sessions.sorted(by: { $0.date > $1.date }) {
            guard result.count < limit else { break }
            let liftSets = session.exercises
                .filter { matches($0, liftId: liftId, liftName: liftName) }
                .flatMap { completedWorkingSets($0) }
            guard let top = liftSets.max(by: { ($0.weight, $0.reps) < ($1.weight, $1.reps) }) else { continue }
            result.append(TopSet(
                display: "\(WeightFormatter.format(top.weight)) \u{00D7} \(top.reps)",
                dateLabel: TimeFormatter.relativeDay(session.date)
            ))
        }
        return result
    }
}
