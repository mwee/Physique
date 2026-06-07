import Foundation
import SwiftData

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var orderIndex: Int
    var exerciseName: String // denormalized for display
    var exercise: Exercise?
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.sessionExercise)
    var sets: [ExerciseSet] = []

    var sortedSets: [ExerciseSet] {
        sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    init(
        orderIndex: Int,
        exerciseName: String,
        exercise: Exercise? = nil,
        session: WorkoutSession? = nil
    ) {
        self.orderIndex = orderIndex
        self.exerciseName = exerciseName
        self.exercise = exercise
        self.session = session
    }
}
