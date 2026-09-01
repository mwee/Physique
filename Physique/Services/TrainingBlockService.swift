import Foundation
import SwiftData

/// Training-block logic for an active program: the maxes captured at
/// activation are *locked* for the block (3 or 6 weeks, or the program's own
/// cycle), sessions are built from those, and at the end of the block the
/// user reviews new maxes suggested from what they actually lifted.
enum TrainingBlockService {

    /// Block lengths offered when activating a program.
    static func blockOptions(for program: ProgramDefinition) -> [Int] {
        var options: Set<Int> = [3, 6]
        if program.cycleWeeks > 1 { options.insert(program.cycleWeeks) }
        return options.sorted()
    }

    /// Default block length: the program's own cycle when it has one.
    static func defaultBlockWeeks(for program: ProgramDefinition) -> Int {
        program.cycleWeeks > 1 ? program.cycleWeeks : 6
    }

    static func isBlockComplete(_ active: ActiveProgram) -> Bool {
        active.weeksInBlock >= max(1, active.blockWeeks)
    }

    /// "Week 2 of 6" (never runs past the block length).
    static func blockLabel(_ active: ActiveProgram) -> String {
        let week = min(active.weeksInBlock + 1, max(1, active.blockWeeks))
        return "Week \(week) of \(max(1, active.blockWeeks))"
    }

    /// 0…1 progress through the block.
    static func blockProgress(_ active: ActiveProgram) -> Double {
        guard active.blockWeeks > 0 else { return 0 }
        return min(1, Double(active.weeksInBlock) / Double(active.blockWeeks))
    }

    /// The locked 1RM the program was activated with, if it trains this lift.
    static func lockedMax(liftId: String, active: ActiveProgram?) -> Double? {
        guard let active, let value = active.maxes[liftId], value > 0 else { return nil }
        return value
    }

    /// The locked training max used for set weights: 1RM × TM% for
    /// training-max programs, the 1RM itself for 1RM-based programs.
    static func lockedTrainingMax(
        liftId: String,
        active: ActiveProgram?,
        definition: ProgramDefinition?
    ) -> Double? {
        guard let active, let definition, let oneRM = lockedMax(liftId: liftId, active: active) else { return nil }
        return ProgramEngine.basisWeight(
            oneRM: oneRM, program: definition, tmPct: active.trainingMaxPercent, unit: active.unit
        )
    }

    /// Suggested 1RM for the next block: whichever is higher — the max you've
    /// actually shown in training, or the locked max plus a conservative bump
    /// (+5 lb / 2.5 kg upper, double that for lower-body lifts).
    static func suggestedMax(liftId: String, locked: Double, calculated: Double?, unit: WeightUnit) -> Double {
        let bump = unit.increment * (ExerciseCatalog.isLowerBody(liftId) ? 2 : 1)
        let floor = locked + bump
        let candidate = max(calculated ?? 0, floor)
        return WeightFormatter.roundToPlate(candidate, unit: unit)
    }

    /// Start the next block with the given maxes. Custom programs restart
    /// their wave cycle; built-ins keep their own week counters.
    static func startNextBlock(
        _ active: ActiveProgram,
        maxes: [String: Double],
        definition: ProgramDefinition,
        now: Date = Date()
    ) {
        active.maxes = maxes
        active.weeksInBlock = 0
        active.blocksCompleted += 1
        active.blockStartedAt = now
        active.maxesLog = active.maxesLog + [MaxesSnapshot(date: now, maxes: maxes)]
        if definition.id.hasPrefix("custom-") {
            active.currentWeek = 0
            active.currentDayIndex = 0
        }
    }

    /// When the current block is scheduled to end (and the TM is reviewed).
    static func nextBumpDate(_ active: ActiveProgram) -> Date {
        Calendar.current.date(byAdding: .day, value: max(1, active.blockWeeks) * 7, to: active.blockStartedAt) ?? active.blockStartedAt
    }

    /// The training max in force for a lift on a given date, from the maxes
    /// log — the steps of the TM staircase on the lift chart.
    static func trainingMaxSteps(
        liftId: String,
        active: ActiveProgram,
        definition: ProgramDefinition
    ) -> [(date: Date, value: Double)] {
        active.maxesLog.compactMap { snapshot in
            guard let oneRM = snapshot.maxes[liftId], oneRM > 0 else { return nil }
            let tm = ProgramEngine.basisWeight(oneRM: oneRM, program: definition, tmPct: active.trainingMaxPercent, unit: active.unit)
            return (snapshot.date, tm)
        }
    }

    /// True when the TM has crept within 5% of the rolling e1RM — the lifter
    /// is training too close to their max and should reset the TM lower.
    static func needsReset(trainingMax: Double, rollingMax: Double?) -> Bool {
        guard let rollingMax, rollingMax > 0 else { return false }
        return trainingMax / rollingMax > 0.95
    }

    /// Fill in any lifts the active program now needs (after a custom program
    /// edit) from the user's current 1RM history, without touching locked values.
    static func fillMissingMaxes(
        _ active: ActiveProgram,
        definition: ProgramDefinition,
        entries: [OneRepMaxEntry],
        sessions: [WorkoutSession]
    ) {
        var maxes = active.maxes
        for liftId in definition.liftIds where (maxes[liftId] ?? 0) <= 0 {
            let history = LiftStatsService.history(
                liftId: liftId, liftName: ExerciseCatalog.displayName(for: liftId),
                entries: entries, sessions: sessions
            )
            if let current = LiftStatsService.currentMax(in: history) {
                maxes[liftId] = WeightFormatter.roundToPlate(current, unit: active.unit)
            } else if let fallback = BuiltInPrograms.defaults[active.unit]?[liftId] {
                maxes[liftId] = fallback
            }
        }
        active.maxes = maxes
    }
}
