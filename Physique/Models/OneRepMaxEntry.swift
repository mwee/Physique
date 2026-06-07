import Foundation
import SwiftData

@Model
final class OneRepMaxEntry {
    var id: UUID = UUID()
    var exerciseId: String = ""
    var exerciseName: String = ""
    var weight: Double = 0
    var unitRaw: String = "lb"

    var date: Date = Date()
    var timeString: String?

    init(
        exerciseId: String,
        exerciseName: String,
        weight: Double,
        unit: WeightUnit = WeightUnit.lb,
        date: Date = Date(),
        timeString: String? = nil
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.weight = weight
        self.unitRaw = unit.rawValue
        self.date = date
        self.timeString = timeString
    }
}
