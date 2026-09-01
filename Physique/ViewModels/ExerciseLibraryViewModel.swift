import SwiftUI
import SwiftData

@Observable
final class ExerciseLibraryViewModel {
    var searchQuery: String = ""
    /// nil shows every equipment type.
    var equipmentFilter: ExerciseType?

    func filteredExercises(_ exercises: [Exercise]) -> [Exercise] {
        exercises.filter { exercise in
            if let equipmentFilter, exercise.equipmentType != equipmentFilter { return false }
            if searchQuery.isEmpty { return true }
            return exercise.name.localizedCaseInsensitiveContains(searchQuery)
                || exercise.equipmentType.displayName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func groupedExercises(_ exercises: [Exercise]) -> [(MuscleGroup, [Exercise])] {
        let filtered = filteredExercises(exercises)
        let grouped = Dictionary(grouping: filtered) { $0.muscleGroup }
        return MuscleGroup.allCases.compactMap { group in
            guard let items = grouped[group], !items.isEmpty else { return nil }
            return (group, items)
        }
    }
}
