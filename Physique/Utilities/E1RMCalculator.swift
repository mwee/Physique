import Foundation

enum E1RMCalculator {
    /// Epley formula: weight * (1 + reps / 30)
    static func estimate(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
