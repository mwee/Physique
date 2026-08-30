import Foundation
import SwiftData

@Model
final class ActiveProgram {
    var id: UUID = UUID()
    var programId: String // "531bbb", "gzclp", etc.
    var maxes: [String: Double] = [String: Double]()
    var trainingMaxPercent: Int = 90
    var includeWarmups: Bool = false
    var currentWeek: Int = 0
    var currentDayIndex: Int = 0
    var unitRaw: String = "lb"
    var activatedAt: Date = Date()

    init(
        programId: String,
        maxes: [String: Double] = [:],
        trainingMaxPercent: Int = 90,
        includeWarmups: Bool = false,
        currentWeek: Int = 0,
        unit: WeightUnit = WeightUnit.lb
    ) {
        self.programId = programId
        self.maxes = maxes
        self.trainingMaxPercent = trainingMaxPercent
        self.includeWarmups = includeWarmups
        self.currentWeek = currentWeek
        self.unitRaw = unit.rawValue
    }
}

