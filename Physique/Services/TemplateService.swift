import Foundation

enum TemplateService {

    /// Convert a saved template into a list of `ActiveExercise` ready for the workout screen.
    static func exercises(from template: WorkoutTemplate) -> [ActiveExercise] {
        switch template.kind {
        case .program:
            return programExercises(from: template)
        case .custom:
            return customExercises(from: template)
        }
    }

    // MARK: - Program-based

    private static func programExercises(from template: WorkoutTemplate) -> [ActiveExercise] {
        guard let programId = template.programId,
              let program = BuiltInPrograms.programs.first(where: { $0.id == programId })
        else { return [] }

        let config = ActiveProgram(
            programId: programId,
            maxes: template.maxes,
            trainingMaxPercent: template.trainingMaxPercent,
            includeWarmups: template.includeWarmups,
            currentWeek: 0,
            unit: template.unit
        )
        return SessionBuilder.buildSession(program: program, config: config, dayIndex: template.dayIndex)
    }

    // MARK: - Custom

    private static func customExercises(from template: WorkoutTemplate) -> [ActiveExercise] {
        template.sortedItems.map { item in
            let sets = (1...max(1, item.targetSets)).map { n in
                ActiveSet(
                    type: .working(n),
                    weight: item.targetWeight,
                    reps: item.targetReps
                )
            }
            let slug = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
            return ActiveExercise(
                exId: item.exerciseId ?? slug,
                name: item.name,
                sets: sets
            )
        }
    }
}
