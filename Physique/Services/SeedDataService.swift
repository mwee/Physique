import Foundation
import SwiftData

enum SeedDataService {
    /// Sample stats attached to the starter lifts on a fresh install so the
    /// app has something to chart before the first workout.
    private static let sampleStats: [String: (e1rm: Double, best: Double, delta: Double, history: [Double])] = [
        "deadlift": (400, 355, 14.5, [350, 355, 355, 370, 380, 375, 390, 400]),
        "bench":    (260, 230, 5.5,  [230, 240, 235, 245, 245, 250, 255, 260]),
        "squat":    (365, 330, 9.0,  [330, 335, 335, 345, 350, 355, 355, 365]),
        "ohp":      (160, 135, 2.0,  [145, 150, 150, 150, 155, 155, 155, 160]),
        "row":      (245, 220, 6.5,  [215, 220, 220, 230, 230, 235, 240, 245]),
        "curl":     (55, 50, 1.0,    [45, 45, 45, 50, 50, 50, 50, 55]),
        "lat":      (200, 175, 4.5,  [175, 180, 180, 185, 185, 190, 195, 200]),
    ]

    /// Inserts every catalog exercise that isn't in the store yet. On a
    /// brand-new store the starter lifts also get sample stats and records.
    static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingIds = Set(existing.map(\.id))
        let isFirstSeed = existing.isEmpty

        var inserted: [Exercise] = []
        for entry in ExerciseCatalog.entries where !existingIds.contains(entry.id) {
            let sample = isFirstSeed ? sampleStats[entry.id] : nil
            let exercise = Exercise(
                id: entry.id,
                name: entry.name,
                muscleGroup: entry.muscleGroup,
                equipmentType: entry.equipment,
                note: entry.id == "deadlift" ? "Watch back rounding" : nil,
                bestEstimated1RM: sample?.e1rm,
                bestWeight: sample?.best,
                e1rmDelta: sample?.delta,
                e1rmHistory: sample?.history ?? (entry.id == "pullup" && isFirstSeed ? [8, 9, 9, 10, 11, 11, 12, 13] : [])
            )
            context.insert(exercise)
            inserted.append(exercise)
        }

        if isFirstSeed {
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
                guard let exercise = inserted.first(where: { $0.id == exId }) else { continue }
                for (type, value, detail) in records {
                    context.insert(ExerciseRecord(exercise: exercise, recordType: type, value: value, detail: detail))
                }
            }
        }

        if !inserted.isEmpty {
            try? context.save()
        }
    }
}
