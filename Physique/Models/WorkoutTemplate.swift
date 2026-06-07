import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String
    var kindRaw: String = "custom" // "program" or "custom"
    var createdAt: Date = Date()

    // Program-based template (kind == .program)
    var programId: String?
    var maxes: [String: Double] = [String: Double]()
    var trainingMaxPercent: Int = 90
    var includeWarmups: Bool = false
    var unitRaw: String = "lb"
    var dayIndex: Int = 0

    // Custom template (kind == .custom)
    @Relationship(deleteRule: .cascade, inverse: \TemplateItem.template)
    var items: [TemplateItem] = []

    init(
        name: String,
        kindRaw: String = "custom",
        programId: String? = nil,
        maxes: [String: Double] = [:],
        trainingMaxPercent: Int = 90,
        includeWarmups: Bool = false,
        unit: WeightUnit = WeightUnit.lb,
        dayIndex: Int = 0
    ) {
        self.name = name
        self.kindRaw = kindRaw
        self.programId = programId
        self.maxes = maxes
        self.trainingMaxPercent = trainingMaxPercent
        self.includeWarmups = includeWarmups
        self.unitRaw = unit.rawValue
        self.dayIndex = dayIndex
    }
}
