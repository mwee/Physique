import Foundation

/// One public number per lift: the rolling-best estimated 1RM.
///
/// Every tested max the user logs (`OneRepMaxEntry`) and every completed
/// working set ≤ 10 reps (Epley) feeds one chronological stream. The value
/// shown anywhere in the app is the maximum of that stream over the trailing
/// `e1rmWindowDays`; when the window is empty the last known value is held
/// and rendered as stale. The training max is a program input and is never
/// derived from — or displayed as — this number.
enum LiftStatsService {

    /// Trailing window for the rolling best (tunable).
    static let e1rmWindowDays = 42
    /// Lookback for the "+10 · 30d" delta label.
    static let deltaWindowDays = 30

    struct DatedMax: Identifiable {
        var id: String { "\(date.timeIntervalSince1970)-\(value)-\(tested)" }
        let date: Date
        let value: Double
        let tested: Bool
    }

    struct SessionLogEntry: Identifiable {
        let id: UUID
        let date: Date
        let topSet: String   // "295 × 3"
        let e1rm: Double
    }

    /// Everything a card or detail screen needs for one lift.
    struct Snapshot {
        let points: [DatedMax]      // raw stream, chronological
        let rolling: [DatedMax]     // rolling-best at each point's date
        let value: Double?          // rolling best now (or last known when stale)
        let isStale: Bool           // no data inside the trailing window
        let delta30: Double?        // change vs. the rolling best 30 days ago
        let isAtPeak: Bool          // current value is the all-time high
    }

    // MARK: - Matching

    private static func matches(_ sessionExercise: SessionExercise, liftId: String, liftName: String) -> Bool {
        if let id = sessionExercise.exercise?.id { return id == liftId }
        return sessionExercise.exerciseName.caseInsensitiveCompare(liftName) == .orderedSame
    }

    private static func completedWorkingSets(_ sessionExercise: SessionExercise) -> [ExerciseSet] {
        sessionExercise.sortedSets.filter { $0.isCompleted && !$0.setType.isWarmup && $0.weight > 0 && $0.reps > 0 }
    }

    // MARK: - Stream

    /// Chronological raw stream: every tested entry plus the best set-level
    /// e1RM of each session that trained the lift (sets > 10 reps ignored).
    static func history(
        liftId: String,
        liftName: String,
        entries: [OneRepMaxEntry],
        sessions: [WorkoutSession]
    ) -> [DatedMax] {
        var points: [DatedMax] = entries
            .filter { $0.exerciseId == liftId && $0.weight > 0 }
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

    // MARK: - Rolling best

    /// Max of the stream inside (`at` − window, `at`]; nil when empty.
    static func rollingValue(in history: [DatedMax], at date: Date, windowDays: Int = e1rmWindowDays) -> Double? {
        let start = Calendar.current.date(byAdding: .day, value: -windowDays, to: date) ?? date
        return history
            .filter { $0.date > start && $0.date <= date }
            .map(\.value)
            .max()
    }

    /// The rolling best evaluated at each point in the stream — the series
    /// the sparkline and detail chart draw.
    static func rollingSeries(_ history: [DatedMax]) -> [DatedMax] {
        history.compactMap { point in
            rollingValue(in: history, at: point.date).map { DatedMax(date: point.date, value: $0, tested: point.tested) }
        }
    }

    /// The lift's current number: rolling best now, or the last known value
    /// when nothing has been logged inside the window.
    static func currentMax(in history: [DatedMax], now: Date = Date()) -> Double? {
        rollingValue(in: history, at: now) ?? history.last?.value
    }

    static func isStale(_ history: [DatedMax], now: Date = Date()) -> Bool {
        !history.isEmpty && rollingValue(in: history, at: now) == nil
    }

    /// Current rolling best minus the rolling best `deltaWindowDays` ago.
    /// nil when there was nothing to compare against or nothing changed.
    static func delta30(in history: [DatedMax], now: Date = Date()) -> Double? {
        guard let current = rollingValue(in: history, at: now),
              let then = Calendar.current.date(byAdding: .day, value: -deltaWindowDays, to: now),
              let previous = rollingValue(in: history, at: then) else { return nil }
        let delta = current - previous
        return delta == 0 ? nil : delta
    }

    /// True when the latest point is the all-time high.
    static func isAtPeak(_ history: [DatedMax]) -> Bool {
        guard let last = history.last?.value,
              let peak = history.map(\.value).max() else { return false }
        return last >= peak
    }

    static func snapshot(
        liftId: String,
        liftName: String,
        entries: [OneRepMaxEntry],
        sessions: [WorkoutSession],
        now: Date = Date()
    ) -> Snapshot {
        let points = history(liftId: liftId, liftName: liftName, entries: entries, sessions: sessions)
        return Snapshot(
            points: points,
            rolling: rollingSeries(points),
            value: currentMax(in: points, now: now),
            isStale: isStale(points, now: now),
            delta30: delta30(in: points, now: now),
            isAtPeak: isAtPeak(points)
        )
    }

    // MARK: - Session log

    /// Newest-first: each session that trained the lift with its top set and
    /// session e1RM.
    static func sessionLog(
        liftId: String,
        liftName: String,
        sessions: [WorkoutSession],
        limit: Int = 12
    ) -> [SessionLogEntry] {
        var result: [SessionLogEntry] = []
        for session in sessions.sorted(by: { $0.date > $1.date }) {
            guard result.count < limit else { break }
            let liftSets = session.exercises
                .filter { matches($0, liftId: liftId, liftName: liftName) }
                .flatMap { completedWorkingSets($0) }
            guard let top = liftSets.max(by: { ($0.weight, $0.reps) < ($1.weight, $1.reps) }) else { continue }
            let e1rm = liftSets.map { E1RMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
            result.append(SessionLogEntry(
                id: session.id,
                date: session.date,
                topSet: "\(WeightFormatter.format(top.weight)) \u{00D7} \(top.reps)",
                e1rm: e1rm
            ))
        }
        return result
    }
}
