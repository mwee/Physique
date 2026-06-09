import Foundation

/// Primary provider: asks the LLM (via the proxy) for a weekly plan as strict JSON,
/// then validates/normalizes it against the real catalog and the user's equipment.
struct LLMCoachPlanProvider: CoachPlanProvider {
    let client = CoachAPIClient()

    func generate(_ request: CoachPlanRequest) async throws -> CoachPlanDraft {
        let raw = try await client.post(
            path: "plan",
            body: [
                "system": Self.systemPrompt,
                "user": Self.userPrompt(request)
            ]
        )

        let json = Self.stripFences(raw)
        guard let data = json.data(using: .utf8) else {
            throw CoachAPIError.decoding(NSError(domain: "Coach", code: 0))
        }

        let draft: CoachPlanDraft
        do {
            draft = try JSONDecoder().decode(CoachPlanDraft.self, from: data)
        } catch {
            throw CoachAPIError.decoding(error)
        }

        return Self.normalize(draft, request: request)
    }

    // MARK: - Prompt

    static let systemPrompt = """
    You are an expert strength coach. Design a weekly training plan and return ONLY \
    valid JSON — no markdown, no commentary — matching exactly this schema:
    {
      "title": string,
      "summary": string,
      "days": [
        {
          "name": string,
          "focus": string,
          "rationale": string,
          "exercises": [
            {
              "exerciseId": string,
              "name": string,
              "sets": number,
              "reps": number,
              "repsUnit": string,
              "targetWeight": number | null,
              "cue": string,
              "why": string
            }
          ]
        }
      ]
    }
    Rules:
    - Pick exercises ONLY from the provided catalog, using its exact "id" as exerciseId.
    - Honor the user's equipment — never select an exercise the user can't perform.
    - Produce exactly the requested number of days.
    - repsUnit is "" for normal reps, or "s" for timed holds (e.g. planks).
    - "cue" is one short coaching cue; "why" explains the exercise choice in 1–2 sentences.
    - Keep the voice warm, concrete and encouraging.
    """

    static func userPrompt(_ r: CoachPlanRequest) -> String {
        let catalog = r.catalog.map {
            "- id=\($0.id) | \($0.name) | \($0.equipment.rawValue) | \($0.muscleGroup.rawValue)"
        }.joined(separator: "\n")
        let maxes = r.maxes.isEmpty
            ? "none logged yet"
            : r.maxes.map { "\($0.key)=\(Int($0.value))" }.joined(separator: ", ")
        return """
        Goal: \(r.goal)
        Experience: \(r.level)
        Days per week: \(r.daysPerWeek)
        Available equipment: \(r.equipment.map(\.rawValue).joined(separator: ", "))
        Weight unit: \(r.unit.rawValue)
        Known 1RMs (\(r.unit.rawValue)): \(maxes)

        Catalog (choose only from these):
        \(catalog)
        """
    }

    // MARK: - Cleaning / validation

    static func stripFences(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            // Drop the opening fence line (``` or ```json) and the closing fence.
            if let firstNewline = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNewline)...])
            }
            if let fenceRange = t.range(of: "```", options: .backwards) {
                t = String(t[..<fenceRange.lowerBound])
            }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validate against the catalog + equipment and clamp to sane ranges.
    static func normalize(_ draft: CoachPlanDraft, request: CoachPlanRequest) -> CoachPlanDraft {
        let byId = Dictionary(uniqueKeysWithValues: request.catalog.map { ($0.id, $0) })
        let byName = Dictionary(request.catalog.map { ($0.name.lowercased(), $0) },
                                uniquingKeysWith: { a, _ in a })
        let allowed = Set(request.equipment)

        let days = draft.days.map { day -> DraftDay in
            let exercises = day.exercises.compactMap { ex -> DraftExercise? in
                // Resolve to a real catalog exercise by id, then by name.
                let match = byId[ex.exerciseId] ?? byName[ex.name.lowercased()]
                guard let cat = match else { return nil }
                // Drop anything the user can't perform.
                guard allowed.isEmpty || allowed.contains(cat.equipment) else { return nil }

                let sets = min(max(ex.sets, 1), 6)
                let isTimed = (ex.repsUnit ?? "") == "s"
                let reps = isTimed ? min(max(ex.reps, 10), 120) : min(max(ex.reps, 1), 30)
                let weight = ex.targetWeight.map { WeightFormatter.roundToPlate($0, unit: request.unit) }

                return DraftExercise(
                    exerciseId: cat.id,
                    name: cat.name,
                    sets: sets,
                    reps: reps,
                    repsUnit: ex.repsUnit ?? "",
                    targetWeight: weight,
                    cue: ex.cue,
                    why: ex.why
                )
            }
            return DraftDay(name: day.name, focus: day.focus, rationale: day.rationale, exercises: exercises)
        }.filter { !$0.exercises.isEmpty }

        return CoachPlanDraft(title: draft.title, summary: draft.summary, days: days)
    }
}
