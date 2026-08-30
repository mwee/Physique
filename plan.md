# Minimal AI Coaching Loop: Post-Workout Plan Revision

## Context

The coach currently authors a plan once and goes quiet — "Regenerate" throws everything away and starts over, and logged workout data is never fed back in. This feature closes the loop minimally: when a **coached** workout finishes, one AI call (with a deterministic double-progression fallback, so it works offline) revises the target weights/reps/sets for that day's exercises and stores a short human-voiced **coach note** explaining what changed. No chat, no new screens — the note appears in the existing sparkles summary card on the Plan tab. Works for all experience levels: beginners get progression handled, intermediates get stall detection and deloads.

## Verified facts the design relies on

- Join key: `Exercise.id` is a unique String slug (e.g. `"bench"`); `CoachPlanExercise.exerciseId` stores that slug; `SessionExercise.exercise?.id` carries it through to logged sessions (with `exerciseName` as a name-match fallback).
- `WorkoutEngine.saveWorkout` persists **only completed** sets; warmups identified via `setType.isWarmup`.
- `WorkoutSession.coachPlanDayId` already links a coached session to its plan day.
- `ActiveWorkoutScreen`'s `modelContext` is the container's long-lived `mainContext` (screen is a fullScreenCover under the app container), so a fire-and-forget `Task { @MainActor in }` from the Finish button is safe after dismissal. **Not** `Task.detached` (would drop MainActor isolation).
- `WeightUnit.increment` = 5 lb / 2.5 kg; `WeightFormatter.roundToPlate` exists. Never read `ExerciseSet.unitRaw` (saveWorkout doesn't set it) — treat weights as `plan.unit`.
- Xcode project uses `fileSystemSynchronizedGroups` — new files are picked up automatically, no pbxproj edits.
- Proxy (`proxy/server.js`) is generic `{system, user} → {text}`; adding `/revise` is trivial.

## New files (mirror the existing `Services/Coach/` provider pattern)

### 1. `Physique/Services/Coach/CoachRevisionProvider.swift` — shapes + protocol

```swift
struct LoggedSet { let weight: Double; let reps: Int }

struct RevisionExercise {
    let exerciseId: String
    let name: String
    let repsUnit: String           // "" | "s"
    let sets: Int                  // current prescription
    let reps: Int
    let targetWeight: Double?
    let logged: [LoggedSet]        // this session's completed working sets
    let priorTopSets: [LoggedSet]  // top working set of previous ≤3 sessions for this day, newest first
    let priorAllHitTargets: [Bool] // per prior session: hit all target reps?
    let bestE1RM: Double?
}

struct CoachRevisionRequest {
    let unit: WeightUnit
    let goal: String
    let level: String
    let dayName: String
    let exercises: [RevisionExercise]
}

struct CoachRevisionDraft: Codable {
    let note: String
    let adjustments: [DraftAdjustment]
}
struct DraftAdjustment: Codable {
    let exerciseId: String
    let targetWeight: Double?
    let reps: Int
    let sets: Int
}

protocol CoachRevisionProvider {
    func revise(_ request: CoachRevisionRequest) async throws -> CoachRevisionDraft
}
```

### 2. `Physique/Services/Coach/FallbackCoachRevisionProvider.swift` — deterministic rules

Per exercise (skip when `logged.isEmpty`); emit an adjustment only when something changes:

```
isTimed    = repsUnit == "s"
isNoWeight = targetWeight == nil && logged.allSatisfy { $0.weight == 0 }
success    = logged.count >= sets && logged.allSatisfy { $0.reps >= reps }
topWeight  = logged.map(\.weight).max() ?? 0

if isTimed:        success → reps = min(reps + 5, 120)        // +5 s hold
else if isNoWeight: success → reps = min(reps + 1, 30)        // +1 rep
else if success:
    anchor = max(targetWeight ?? 0, topWeight)
    targetWeight = roundToPlate(anchor + unit.increment, unit) // one increment up
else:
    // stalled: this session failed AND previous 2 sessions for this day
    // also failed at ~the same top weight → deload ~10%
    stalled = priorTopSets.count >= 2
           && priorAllHitTargets.prefix(2).allSatisfy { !$0 }
           && priorTopSets.prefix(2).allSatisfy { abs($0.weight - topWeight) < 0.1 }
    if stalled: targetWeight = roundToPlate(topWeight * 0.9, unit)
    else: hold (no adjustment)
```

Include a **note builder** (also reused by the LLM provider as a safety net): warm 1–3 sentence summary, e.g. "Solid session. Bench Press moves up to 105 lb; Plank stretches to 45 s. Squat holds — chase 8 clean reps next time." If nothing changed, still return a hold-note ("Everything holds this week — beat your rep targets to earn the next bump.") so the user always sees a coach reaction.

### 3. `Physique/Services/Coach/LLMCoachRevisionProvider.swift`

- `client.post(path: "revise", body: ["system": ..., "user": ...])`, reuse `LLMCoachPlanProvider.stripFences` (already static), decode `CoachRevisionDraft`, then `normalize`.
- **System prompt**: expert coach revising after a workout; return ONLY the strict JSON above; include entries only for exercises that change; double-progression rules (raise one increment on full success, hold on misses, deload ~10% after ~3 stuck sessions, +5 s for timed holds, +1 rep for bodyweight); never change a weight by more than 15%; note = 1–3 warm second-person sentences, no markdown.
- **User prompt**: unit/goal/level/day header, then per exercise: current prescription, today's working sets, recent top sets + whether targets were hit.
- **`normalize(_:request:)`** (static, mirrors `LLMCoachPlanProvider.normalize`):
  - Drop adjustments whose `exerciseId` isn't in the day; dedupe by id.
  - Clamp `sets` 1–6; `reps` 1–30 (10–120 when timed).
  - Weight: timed → forced nil. Current target nil and no logged weight > 0 → forced nil (bodyweight stays bodyweight). Otherwise anchor = current target ?? top logged weight; clamp to anchor × 0.85…1.15, cap at `bestE1RM` if present, then `roundToPlate`.
  - Drop adjustments identical to the current prescription (the note must never claim a change that didn't apply).
  - Trim note (~400 char cap); if note empty but adjustments survive, synthesize via the fallback note builder.

## Modified files

### 4. `Physique/Models/CoachPlan.swift` — add after `sourceRaw`
```swift
var coachNote: String = ""
var coachNoteDate: Date?
```
Defaults/optional → automatic lightweight migration. Regeneration creates a new `CoachPlan`, so the note auto-clears on regenerate (correct behavior for free).

### 5. `Physique/Services/CoachPlanService.swift` — add revision flow

Add `revisionLLM: CoachRevisionProvider = LLMCoachRevisionProvider()` and `revisionFallback = FallbackCoachRevisionProvider()`, plus:

```swift
@MainActor func reviseAfterWorkout(session: WorkoutSession, context: ModelContext) async -> Bool
```
1. Guard `session.coachPlanDayId`; fetch current plan, find the day by id (confirms it belongs to the live plan). Abort → false.
2. Matching helper (static, testable): `matchedPerformance(day:session:)` → for each `day.sortedExercises`, first `session.exercises` where `exercise?.id == planEx.exerciseId`, else name match (lowercased); working sets = completed, non-warmup. Drop pairs with zero working sets. Ad-hoc exercises the user added never match — ignored by design.
3. Guard ≥1 match → else return false (abandoned workout: no note).
4. History: `FetchDescriptor<WorkoutSession>` where `coachPlanDayId == dayId && id != session.id`, sorted by date desc, `prefix(3)`; same matching per prior session → `priorTopSets` / `priorAllHitTargets`. (A "repeat workout" same week just becomes the newest history point and revises again from the already-bumped targets — intended double-progression behavior.)
5. Build `CoachRevisionRequest` (unit/goal/level from plan; `bestE1RM` from the matched `Exercise`).
6. `try await revisionLLM.revise(request)` → on any error, `revisionFallback.revise(request)` (silent on `.notConfigured`, same pattern as `generateAndStore`).
7. **Re-fetch the day by id after the await** — if gone (plan regenerated mid-flight), abort. 
8. Apply adjustments to `day.exercises` by `exerciseId`; set `plan.coachNote` / `coachNoteDate = Date()`; `try? context.save()`; return true.

### 6. `Physique/Views/Workout/ActiveWorkoutScreen.swift` — Finish button (~line 189)
```swift
Button {
    let session = wk.finishWorkout(context: modelContext)
    appCoordinator.isWorkoutActive = false
    appCoordinator.showToast("Workout saved", icon: "checkmark", tone: .success)
    if session.coachPlanDayId != nil {
        let context = modelContext
        Task { @MainActor in
            if await CoachPlanService().reviseAfterWorkout(session: session, context: context) {
                appCoordinator.showToast("Coach updated your plan", icon: "sparkles", tone: .success)
            }
        }
    }
} label: { Text("Finish") }
```
(Check `ToastTone` cases; use whichever neutral/success tone exists.)

### 7. `Physique/Views/Plan/CoachBody.swift` — summary card (lines 56–76)
Show `plan.coachNote` when non-empty, else `plan.summary`; when showing the note, add a relative-date caption (`Text(date, format: .relative(presentation: .named))` in `theme.text3`). Same sparkles icon, background, and padding as today.

### 8. `proxy/server.js` — add `POST /revise`
Copy of `/plan` route with `max_tokens: 1024`; update the routes comment at the top of the file.

## Implementation order

1. `CoachPlan` fields (4) → 2. shapes (1) → 3. fallback provider (3, pure logic) → 4. LLM provider + normalize (2) → 5. `reviseAfterWorkout` + matching/history helpers (5) → 6. trigger (6) + note card (7) → 7. proxy route (8).

## Verification

1. **Fallback path** (no `COACH_API_BASE_URL` configured): build & run in the simulator (`xcodebuild`/Xcode). Generate a plan, start Day A coached, complete all working sets at/above target on one weighted exercise, miss reps on another, complete the timed hold; Finish. Expect both toasts; Plan tab card shows the coach note + relative date; successful lift +5 lb (or +2.5 kg, plate-rounded), missed lift unchanged, hold +5 s.
2. **Stall/deload**: repeat the day twice more missing reps at the same weight → third finish drops that target ~10% and the note says why.
3. **LLM path**: `cd proxy && ANTHROPIC_API_KEY=... npm start`, set `COACH_API_BASE_URL` in Secrets.xcconfig, rebuild; finish a coached day, watch the proxy log `/revise`; log an absurd weight (e.g. 999) and confirm the applied target stays within ±15% of the prior target.
4. **Race**: finish a coached workout and immediately tap "Regenerate plan" — no crash; new plan shows its fresh summary, no stale note.
5. **Non-coached** (blank/template) workout → no revision, no second toast.
6. **Migration**: existing install with a plan upgrades cleanly; card shows `summary` until the first coached finish.
