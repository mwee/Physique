import Foundation
import SwiftData

@Model
final class CoachPlanExercise {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var exerciseId: String = "" // Exercise.id or slug
    var name: String = ""
    var sets: Int = 3
    var reps: Int = 8
    var repsUnit: String = "" // "" | "s" (seconds, e.g. plank)
    var targetWeight: Double?
    var cue: String = ""
    var why: String = ""

    var day: CoachPlanDay?

    init(
        orderIndex: Int,
        exerciseId: String,
        name: String,
        sets: Int,
        reps: Int,
        repsUnit: String = "",
        targetWeight: Double? = nil,
        cue: String = "",
        why: String = ""
    ) {
        self.orderIndex = orderIndex
        self.exerciseId = exerciseId
        self.name = name
        self.sets = sets
        self.reps = reps
        self.repsUnit = repsUnit
        self.targetWeight = targetWeight
        self.cue = cue
        self.why = why
    }
}
