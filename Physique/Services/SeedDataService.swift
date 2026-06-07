import Foundation
import SwiftData

enum SeedDataService {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let exercises = [
            Exercise(
                id: "deadlift", name: "Deadlift",
                muscleGroup: .back, equipmentType: .barbell,
                note: "Watch back rounding",
                bestEstimated1RM: 400, bestWeight: 355, e1rmDelta: 14.5,
                e1rmHistory: [350, 355, 355, 370, 380, 375, 390, 400]
            ),
            Exercise(
                id: "bench", name: "Bench Press",
                muscleGroup: .chest, equipmentType: .barbell,
                bestEstimated1RM: 260, bestWeight: 230, e1rmDelta: 5.5,
                e1rmHistory: [230, 240, 235, 245, 245, 250, 255, 260]
            ),
            Exercise(
                id: "squat", name: "Back Squat",
                muscleGroup: .legs, equipmentType: .barbell,
                bestEstimated1RM: 365, bestWeight: 330, e1rmDelta: 9.0,
                e1rmHistory: [330, 335, 335, 345, 350, 355, 355, 365]
            ),
            Exercise(
                id: "ohp", name: "Overhead Press",
                muscleGroup: .shoulders, equipmentType: .barbell,
                bestEstimated1RM: 160, bestWeight: 135, e1rmDelta: 2.0,
                e1rmHistory: [145, 150, 150, 150, 155, 155, 155, 160]
            ),
            Exercise(
                id: "row", name: "Barbell Row",
                muscleGroup: .back, equipmentType: .barbell,
                bestEstimated1RM: 245, bestWeight: 220, e1rmDelta: 6.5,
                e1rmHistory: [215, 220, 220, 230, 230, 235, 240, 245]
            ),
            Exercise(
                id: "pullup", name: "Pull Up",
                muscleGroup: .back, equipmentType: .bodyweight,
                e1rmHistory: [8, 9, 9, 10, 11, 11, 12, 13]
            ),
            Exercise(
                id: "curl", name: "Dumbbell Curl",
                muscleGroup: .arms, equipmentType: .dumbbell,
                bestEstimated1RM: 55, bestWeight: 50, e1rmDelta: 1.0,
                e1rmHistory: [45, 45, 45, 50, 50, 50, 50, 55]
            ),
            Exercise(
                id: "lat", name: "Lat Pulldown",
                muscleGroup: .back, equipmentType: .machine,
                bestEstimated1RM: 200, bestWeight: 175, e1rmDelta: 4.5,
                e1rmHistory: [175, 180, 180, 185, 185, 190, 195, 200]
            ),
        ]

        for exercise in exercises {
            context.insert(exercise)
        }

        // Seed records for each exercise
        let recordData: [(String, [(String, Double, String)])] = [
            ("deadlift", [("weight", 355, "355 lb \u{00D7} 1"), ("e1rm", 400, "400 lb"), ("volume", 10630, "10,630 lb")]),
            ("bench", [("weight", 230, "230 lb \u{00D7} 1"), ("e1rm", 260, "260 lb"), ("volume", 6880, "6,880 lb")]),
            ("squat", [("weight", 330, "330 lb \u{00D7} 1"), ("e1rm", 365, "365 lb"), ("volume", 11910, "11,910 lb")]),
            ("ohp", [("weight", 135, "135 lb \u{00D7} 2"), ("e1rm", 160, "160 lb"), ("volume", 4100, "4,100 lb")]),
            ("row", [("weight", 220, "220 lb \u{00D7} 2"), ("e1rm", 245, "245 lb"), ("volume", 6480, "6,480 lb")]),
            ("curl", [("weight", 50, "50 lb \u{00D7} 8"), ("e1rm", 55, "55 lb"), ("volume", 2470, "2,470 lb")]),
            ("lat", [("weight", 175, "175 lb \u{00D7} 6"), ("e1rm", 200, "200 lb"), ("volume", 4760, "4,760 lb")]),
        ]

        for (exId, records) in recordData {
            if let exercise = exercises.first(where: { $0.id == exId }) {
                for (type, value, detail) in records {
                    let record = ExerciseRecord(
                        exercise: exercise,
                        recordType: type,
                        value: value,
                        detail: detail
                    )
                    context.insert(record)
                }
            }
        }

        try? context.save()
    }
}
