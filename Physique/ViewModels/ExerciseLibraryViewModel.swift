import SwiftUI
import SwiftData

@Observable
final class ExerciseLibraryViewModel {
    var searchQuery: String = ""

    func filteredExercises(_ exercises: [Exercise]) -> [Exercise] {
        guard !searchQuery.isEmpty else { return exercises }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
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
