import Foundation

// Computed WeightUnit accessors kept out of @Model files
// so the SwiftData macro doesn't pick them up as schema properties.

extension ActiveProgram {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }
}

extension BodyweightEntry {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }
}

extension ExerciseSet {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }
}

extension OneRepMaxEntry {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }
}

extension UserProfile {
    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
        set { weightUnitRaw = newValue.rawValue }
    }

    var equipment: [ExerciseType] {
        get { equipmentRaw.split(separator: ",").compactMap { ExerciseType(rawValue: String($0)) } }
        set { equipmentRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }
}

enum TemplateKind: String {
    case program
    case custom
}

enum CoachPlanSource: String {
    case llm
    case fallback
}

extension CoachPlan {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }

    var source: CoachPlanSource {
        get { CoachPlanSource(rawValue: sourceRaw) ?? .llm }
        set { sourceRaw = newValue.rawValue }
    }

    var sortedDays: [CoachPlanDay] {
        days.sorted { $0.orderIndex < $1.orderIndex }
    }
}

extension CoachPlanDay {
    var sortedExercises: [CoachPlanExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

extension WorkoutTemplate {
    var kind: TemplateKind {
        get { TemplateKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }

    var sortedItems: [TemplateItem] {
        items.sorted { $0.orderIndex < $1.orderIndex }
    }
}
