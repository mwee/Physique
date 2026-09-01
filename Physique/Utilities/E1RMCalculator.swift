import Foundation

enum E1RMCalculator {
    /// Sets above this rep count are too formula-inflated to count as a max estimate.
    static let maxRepsForEstimate = 10

    /// Epley formula: weight × (1 + reps / 30). Returns 0 for sets that
    /// shouldn't feed the estimate (no load, no reps, or > 10 reps).
    static func estimate(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0, reps <= maxRepsForEstimate else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
