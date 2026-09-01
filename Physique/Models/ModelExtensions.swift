import Foundation

// Computed WeightUnit accessors kept out of @Model files
// so the SwiftData macro doesn't pick them up as schema properties.

/// The maxes an active program was using from a given date.
struct MaxesSnapshot: Codable {
    var date: Date
    var maxes: [String: Double]
}

extension ActiveProgram {
    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }

    /// Chronological log of the maxes in force; falls back to the current
    /// maxes from activation when nothing has been recorded yet.
    var maxesLog: [MaxesSnapshot] {
        get {
            let decoded = (try? JSONDecoder().decode([MaxesSnapshot].self, from: maxesLogData)) ?? []
            return decoded.isEmpty ? [MaxesSnapshot(date: activatedAt, maxes: maxes)] : decoded
        }
        set { maxesLogData = (try? JSONEncoder().encode(newValue)) ?? Data() }
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

/// One prescribed set inside a template item.
struct TemplateSetSpec: Codable, Equatable {
    var weight: Double
    var reps: Int
}

extension TemplateItem {
    /// Per-set prescriptions; falls back to expanding the uniform targets.
    var setSpecs: [TemplateSetSpec] {
        get {
            let decoded = (try? JSONDecoder().decode([TemplateSetSpec].self, from: setsData)) ?? []
            if !decoded.isEmpty { return decoded }
            return (0..<max(1, targetSets)).map { _ in TemplateSetSpec(weight: targetWeight, reps: targetReps) }
        }
        set { setsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
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
