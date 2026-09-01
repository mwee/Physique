import Foundation
import SwiftData

/// Resolves an `ActiveProgram` to its definition (built-in or custom),
/// builds the next session, and advances day/week state after a finish.
enum ProgramResolver {

    static func definition(
        for active: ActiveProgram,
        customPrograms: [CustomProgram]
    ) -> ProgramDefinition? {
        if let builtIn = BuiltInPrograms.find(active.programId) { return builtIn }
        return customPrograms
            .first { $0.programId == active.programId }?
            .definition(forWeek: active.currentWeek)
    }

    /// The split day the user trains next (clamped so stale indices never crash).
    static func currentDay(of definition: ProgramDefinition, active: ActiveProgram) -> SplitDay? {
        guard !definition.split.isEmpty else { return nil }
        return definition.split[min(max(0, active.currentDayIndex), definition.split.count - 1)]
    }

    /// Builds the next session's exercises and links them to the exercise
    /// catalog so PRs and e1RM history update when the workout is saved.
    static func sessionExercises(
        for active: ActiveProgram,
        definition: ProgramDefinition,
        catalog: [Exercise]
    ) -> [ActiveExercise] {
        let dayIndex = min(max(0, active.currentDayIndex), definition.split.count - 1)
        var exercises = SessionBuilder.buildSession(program: definition, config: active, dayIndex: dayIndex)
        for index in exercises.indices {
            exercises[index].exercise = catalog.first { $0.id == exercises[index].exId }
        }
        return exercises
    }

    /// A short week label, using the program's week names when it has them.
    static func weekLabel(for active: ActiveProgram, definition: ProgramDefinition) -> String {
        if let names = definition.weekNames, active.currentWeek < names.count {
            return names[active.currentWeek]
        }
        return "Week \(active.currentWeek + 1)"
    }

    /// Move to the next day; rolling past the last day starts the next week.
    /// Week-block programs (5/3/1) wrap back to week 1 after their cycle so
    /// the deload week doesn't repeat forever; ramping programs keep counting.
    static func advance(_ active: ActiveProgram, definition: ProgramDefinition) {
        active.currentDayIndex += 1
        if active.currentDayIndex >= definition.split.count {
            active.currentDayIndex = 0
            active.currentWeek += 1
            active.weeksInBlock += 1
            if definition.useWeekBlock && active.currentWeek >= definition.cycleWeeks {
                active.currentWeek = 0
            }
        }
    }

    /// Fetch-and-advance used by the workout finish path.
    static func advanceActiveProgram(context: ModelContext) {
        let actives = (try? context.fetch(FetchDescriptor<ActiveProgram>())) ?? []
        let customs = (try? context.fetch(FetchDescriptor<CustomProgram>())) ?? []
        guard let active = actives.first,
              let definition = definition(for: active, customPrograms: customs) else { return }
        advance(active, definition: definition)
        try? context.save()
    }
}
