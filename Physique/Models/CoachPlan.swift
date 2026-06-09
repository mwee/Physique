import Foundation
import SwiftData

@Model
final class CoachPlan {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var title: String = ""
    var summary: String = "" // overall rationale (LLM voice)
    var goal: String = ""
    var level: String = ""
    var daysPerWeek: Int = 3
    var unitRaw: String = "lb"
    var sourceRaw: String = "llm" // "llm" | "fallback"

    @Relationship(deleteRule: .cascade, inverse: \CoachPlanDay.plan)
    var days: [CoachPlanDay] = []

    init(
        title: String,
        summary: String,
        goal: String,
        level: String,
        daysPerWeek: Int,
        unit: WeightUnit = WeightUnit.lb,
        source: CoachPlanSource = .llm
    ) {
        self.title = title
        self.summary = summary
        self.goal = goal
        self.level = level
        self.daysPerWeek = daysPerWeek
        self.unitRaw = unit.rawValue
        self.sourceRaw = source.rawValue
    }
}
