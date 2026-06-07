import Foundation

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case machine
    case bodyweight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .bodyweight: "Bodyweight"
        }
    }

    var icon: String {
        switch self {
        case .barbell: "figure.strengthtraining.traditional"
        case .dumbbell: "dumbbell.fill"
        case .machine: "gearshape.fill"
        case .bodyweight: "figure.run"
        }
    }
}
