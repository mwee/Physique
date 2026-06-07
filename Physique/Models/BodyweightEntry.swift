import Foundation
import SwiftData

@Model
final class BodyweightEntry {
    var id: UUID = UUID()
    var weight: Double
    var unitRaw: String = "lb"

    var date: Date
    var timeString: String?

    init(
        weight: Double,
        unit: WeightUnit = WeightUnit.lb,
        date: Date = Date(),
        timeString: String? = nil
    ) {
        self.weight = weight
        self.unitRaw = unit.rawValue
        self.date = date
        self.timeString = timeString
    }
}