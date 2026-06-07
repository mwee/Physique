import Foundation
import SwiftData

@Model
final class TemplateItem {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var exerciseId: String?
    var name: String
    var targetSets: Int = 3
    var targetReps: Int = 5
    var targetWeight: Double = 0
    var template: WorkoutTemplate?

    init(
        orderIndex: Int,
        name: String,
        exerciseId: String? = nil,
        targetSets: Int = 3,
        targetReps: Int = 5,
        targetWeight: Double = 0
    ) {
        self.orderIndex = orderIndex
        self.name = name
        self.exerciseId = exerciseId
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
    }
}
