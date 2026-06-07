import Foundation

enum WeightUnit: String, Codable {
    case kg
    case lb

    var increment: Double {
        switch self {
        case .kg: 2.5
        case .lb: 5.0
        }
    }

    var displayName: String { rawValue }
}
