import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var goal: String?
    var experienceLevel: String?
    var daysPerWeek: Int = 4
    var weightUnitRaw: String = "lb"
    var equipmentRaw: String = "" // CSV of ExerciseType.rawValue

    var trainingMode: String = "template" // "template" or "coach"
    var displayName: String = ""
    var defaultTrainingMaxPercent: Int = 90
    var hasCompletedOnboarding: Bool = false
    var createdAt: Date = Date()

    init(
        goal: String? = nil,
        experienceLevel: String? = nil,
        daysPerWeek: Int = 4,
        weightUnit: WeightUnit = WeightUnit.lb,
        equipment: [ExerciseType] = [],
        trainingMode: String = "template",
        hasCompletedOnboarding: Bool = false,
        displayName: String = "",
        defaultTrainingMaxPercent: Int = 90
    ) {
        self.goal = goal
        self.experienceLevel = experienceLevel
        self.daysPerWeek = daysPerWeek
        self.weightUnitRaw = weightUnit.rawValue
        self.equipmentRaw = equipment.map(\.rawValue).joined(separator: ",")
        self.trainingMode = trainingMode
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayName = displayName
        self.defaultTrainingMaxPercent = defaultTrainingMaxPercent
    }
}