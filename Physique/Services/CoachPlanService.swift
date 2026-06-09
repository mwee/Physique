import Foundation
import SwiftData

@Observable
final class CoachPlanService {
    var isLoading = false
    var lastError: String?

    private let llm: CoachPlanProvider = LLMCoachPlanProvider()
    private let fallback: CoachPlanProvider = FallbackCoachPlanProvider()
    private let client = CoachAPIClient()

    // MARK: - Generation

    /// Generate a plan (LLM first, deterministic fallback on any failure), then replace
    /// any existing `CoachPlan` and persist the new one.
    @MainActor
    func generateAndStore(from request: CoachPlanRequest, context: ModelContext) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        var source: CoachPlanSource = .llm
        var draft: CoachPlanDraft
        do {
            draft = try await llm.generate(request)
            if draft.days.isEmpty { throw CoachAPIError.decoding(NSError(domain: "Coach", code: 1)) }
        } catch {
            source = .fallback
            if case CoachAPIError.notConfigured = error {
                lastError = nil // expected before a proxy exists — silent
            } else {
                lastError = "Couldn't reach your coach — using an offline plan."
            }
            draft = (try? await fallback.generate(request)) ?? CoachPlanDraft(title: "", summary: "", days: [])
        }

        store(draft, request: request, source: source, context: context)
    }

    @MainActor
    private func store(_ draft: CoachPlanDraft, request: CoachPlanRequest, source: CoachPlanSource, context: ModelContext) {
        // Replace any prior plan.
        let existing = (try? context.fetch(FetchDescriptor<CoachPlan>())) ?? []
        for plan in existing { context.delete(plan) }

        let plan = CoachPlan(
            title: draft.title,
            summary: draft.summary,
            goal: request.goal,
            level: request.level,
            daysPerWeek: request.daysPerWeek,
            unit: request.unit,
            source: source
        )
        context.insert(plan)

        for (dayIndex, draftDay) in draft.days.enumerated() {
            let day = CoachPlanDay(
                orderIndex: dayIndex,
                name: draftDay.name,
                focus: draftDay.focus,
                rationale: draftDay.rationale
            )
            day.plan = plan
            context.insert(day)

            for (exIndex, draftEx) in draftDay.exercises.enumerated() {
                let ex = CoachPlanExercise(
                    orderIndex: exIndex,
                    exerciseId: draftEx.exerciseId,
                    name: draftEx.name,
                    sets: draftEx.sets,
                    reps: draftEx.reps,
                    repsUnit: draftEx.repsUnit ?? "",
                    targetWeight: draftEx.targetWeight,
                    cue: draftEx.cue,
                    why: draftEx.why
                )
                ex.day = day
                context.insert(ex)
            }
        }

        try? context.save()
    }

    // MARK: - Request building

    static func catalog(from exercises: [Exercise]) -> [CatalogExercise] {
        exercises.map {
            CatalogExercise(id: $0.id, name: $0.name, equipment: $0.equipmentType, muscleGroup: $0.muscleGroup)
        }
    }

    /// Latest logged 1RM per exercise id, in the given unit.
    static func maxes(from entries: [OneRepMaxEntry], unit: WeightUnit) -> [String: Double] {
        var result: [String: Double] = [:]
        for entry in entries.sorted(by: { $0.date > $1.date }) where entry.unitRaw == unit.rawValue {
            if result[entry.exerciseId] == nil {
                result[entry.exerciseId] = entry.weight
            }
        }
        return result
    }

    static func makeRequest(
        goal: String,
        level: String,
        daysPerWeek: Int,
        equipment: [ExerciseType],
        unit: WeightUnit,
        exercises: [Exercise],
        oneRepMaxes: [OneRepMaxEntry]
    ) -> CoachPlanRequest {
        CoachPlanRequest(
            goal: goal,
            level: level,
            daysPerWeek: daysPerWeek,
            equipment: equipment,
            unit: unit,
            catalog: catalog(from: exercises),
            maxes: maxes(from: oneRepMaxes, unit: unit)
        )
    }

    // MARK: - Launch a day through the existing workout flow

    /// Build `[ActiveExercise]` for a coach day. CRITICAL: resolve each `exerciseId` to a
    /// real `Exercise` so PRs and e1RM update just like template/blank workouts.
    static func activeExercises(for day: CoachPlanDay, catalog: [Exercise]) -> [ActiveExercise] {
        let byId = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return day.sortedExercises.map { ex in
            let resolved = byId[ex.exerciseId]
            let sets = (0..<max(1, ex.sets)).map { n in
                ActiveSet(
                    type: .working(n + 1),
                    weight: ex.targetWeight ?? 0,
                    reps: ex.reps
                )
            }
            return ActiveExercise(
                exId: ex.exerciseId,
                name: ex.name,
                exercise: resolved,
                cue: ex.cue,
                sets: sets
            )
        }
    }

    // MARK: - Day-completion (derived from sessions, scoped to current week)

    private static func startOfCurrentWeek() -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }

    /// Latest completion date this week, keyed by `CoachPlanDay.id`.
    static func completions(for plan: CoachPlan, sessions: [WorkoutSession]) -> [UUID: Date] {
        let weekStart = startOfCurrentWeek()
        var result: [UUID: Date] = [:]
        for session in sessions {
            guard session.date >= weekStart, let dayId = session.coachPlanDayId else { continue }
            if let existing = result[dayId], existing >= session.date { continue }
            result[dayId] = session.date
        }
        return result
    }

    static func isDoneThisWeek(_ day: CoachPlanDay, sessions: [WorkoutSession]) -> Bool {
        let weekStart = startOfCurrentWeek()
        return sessions.contains { $0.coachPlanDayId == day.id && $0.date >= weekStart }
    }

    static func daysCompletedThisWeek(_ plan: CoachPlan, sessions: [WorkoutSession]) -> Int {
        plan.sortedDays.filter { isDoneThisWeek($0, sessions: sessions) }.count
    }

    /// First day not yet completed this week, or nil when the week is complete.
    static func nextDay(_ plan: CoachPlan, sessions: [WorkoutSession]) -> CoachPlanDay? {
        plan.sortedDays.first { !isDoneThisWeek($0, sessions: sessions) }
    }

    // MARK: - Ask your coach

    func ask(_ text: String, plan: CoachPlan) async -> String {
        do {
            return try await client.post(
                path: "ask",
                body: [
                    "question": text,
                    "plan": plan.title,
                    "goal": plan.goal,
                    "level": plan.level
                ]
            )
        } catch {
            return "That's a great question. For now, stick with the plan and track how it feels — we'll adjust as you go."
        }
    }
}
