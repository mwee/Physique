import Foundation
import SwiftData

@Model
final class CoachPlanDay {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var name: String = "" // e.g. "Day A · Full Body"
    var focus: String = "" // e.g. "Full Body", "Push"
    var rationale: String = ""

    @Relationship(deleteRule: .cascade, inverse: \CoachPlanExercise.day)
    var exercises: [CoachPlanExercise] = []

    var plan: CoachPlan?

    init(
        orderIndex: Int,
        name: String,
        focus: String,
        rationale: String
    ) {
        self.orderIndex = orderIndex
        self.name = name
        self.focus = focus
        self.rationale = rationale
    }
}
