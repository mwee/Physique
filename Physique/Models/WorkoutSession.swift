import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var duration: TimeInterval // seconds
    var totalVolume: Double
    var totalSets: Int
    var prCount: Int
    var notes: String?

    /// Links a finished session back to the coach day it was launched from (nil for
    /// template/blank workouts). Single source of truth for coach day-completion.
    var coachPlanDayId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    var sortedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }

    init(
        name: String,
        date: Date = Date(),
        duration: TimeInterval = 0,
        totalVolume: Double = 0,
        totalSets: Int = 0,
        prCount: Int = 0,
        notes: String? = nil
    ) {
        self.name = name
        self.date = date
        self.duration = duration
        self.totalVolume = totalVolume
        self.totalSets = totalSets
        self.prCount = prCount
        self.notes = notes
    }
}
