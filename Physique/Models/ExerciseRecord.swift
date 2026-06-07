import Foundation
import SwiftData

@Model
final class ExerciseRecord {
    var id: UUID = UUID()
    var exercise: Exercise?
    var recordType: String // "weight", "e1rm", "volume"
    var value: Double
    var detail: String // "355 lb × 1"
    var date: Date

    init(
        exercise: Exercise? = nil,
        recordType: String,
        value: Double,
        detail: String,
        date: Date = Date()
    ) {
        self.exercise = exercise
        self.recordType = recordType
        self.value = value
        self.detail = detail
        self.date = date
    }
}
