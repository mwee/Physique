import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID = UUID()
    var orderIndex: Int
    var setType: SetType
    var weight: Double
    var reps: Int
    var isCompleted: Bool = false
    var isPersonalRecord: Bool = false
    var unitRaw: String = "lb"

    var sessionExercise: SessionExercise?

    var volume: Double {
        guard !setType.isWarmup else { return 0 }
        return weight * Double(reps)
    }

    var displayString: String {
        let w = weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
        let suffix = setType.isWarmup ? " W" : ""
        let pr = isPersonalRecord ? " \u{2605}" : ""
        return "\(w)\u{00D7}\(reps)\(suffix)\(pr)"
    }

    init(
        orderIndex: Int,
        setType: SetType,
        weight: Double,
        reps: Int,
        isCompleted: Bool = false,
        isPersonalRecord: Bool = false,
        unit: WeightUnit = WeightUnit.lb
    ) {
        self.orderIndex = orderIndex
        self.setType = setType
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.isPersonalRecord = isPersonalRecord
        self.unitRaw = unit.rawValue
    }
}