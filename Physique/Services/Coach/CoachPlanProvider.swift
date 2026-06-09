import Foundation

// MARK: - Request

/// A catalog exercise the generator is allowed to choose from. Mirrors the seeded
/// `Exercise` set so the LLM (and fallback) only ever picks real `exerciseId`s.
struct CatalogExercise {
    let id: String
    let name: String
    let equipment: ExerciseType
    let muscleGroup: MuscleGroup
}

/// Everything a provider needs to author a weekly plan. Built from onboarding answers
/// plus the live exercise catalog and any logged 1RMs.
struct CoachPlanRequest {
    let goal: String
    let level: String
    let daysPerWeek: Int
    let equipment: [ExerciseType]
    let unit: WeightUnit
    let catalog: [CatalogExercise]
    let maxes: [String: Double] // exerciseId -> weight (may be empty at onboarding)
}

// MARK: - Draft (LLM JSON shape)

/// Plain Codable shape decoded from the LLM (or produced by the fallback). The service
/// maps this into the `@Model` graph — persistence never knows the source.
struct CoachPlanDraft: Codable {
    let title: String
    let summary: String
    let days: [DraftDay]
}

struct DraftDay: Codable {
    let name: String
    let focus: String
    let rationale: String
    let exercises: [DraftExercise]
}

struct DraftExercise: Codable {
    let exerciseId: String
    let name: String
    let sets: Int
    let reps: Int
    let repsUnit: String?
    let targetWeight: Double?
    let cue: String
    let why: String
}

// MARK: - Provider

protocol CoachPlanProvider {
    func generate(_ request: CoachPlanRequest) async throws -> CoachPlanDraft
}
