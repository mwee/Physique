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
    /// JSON `[TemplateSetSpec]` — individual weight × reps per set. When
    /// empty, the uniform target fields above describe every set (legacy).
    var setsData: Data = Data()
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
