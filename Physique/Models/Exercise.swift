import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var muscleGroup: MuscleGroup
    var equipmentType: ExerciseType
    var note: String?
    var isCustom: Bool = false

    // Cached aggregates (updated after each session)
    var bestEstimated1RM: Double?
    var bestWeight: Double?
    var e1rmDelta: Double?
    var e1rmHistory: [Double] = []

    @Relationship(deleteRule: .cascade, inverse: \ExerciseRecord.exercise)
    var records: [ExerciseRecord] = []

    @Relationship(inverse: \SessionExercise.exercise)
    var sessionExercises: [SessionExercise] = []

    init(
        id: String,
        name: String,
        muscleGroup: MuscleGroup,
        equipmentType: ExerciseType,
        note: String? = nil,
        isCustom: Bool = false,
        bestEstimated1RM: Double? = nil,
        bestWeight: Double? = nil,
        e1rmDelta: Double? = nil,
        e1rmHistory: [Double] = []
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipmentType = equipmentType
        self.note = note
        self.isCustom = isCustom
        self.bestEstimated1RM = bestEstimated1RM
        self.bestWeight = bestWeight
        self.e1rmDelta = e1rmDelta
        self.e1rmHistory = e1rmHistory
    }
}
