import Foundation

nonisolated enum SetType: Codable, Hashable {
    case warmup
    case working(Int)

    var label: String {
        switch self {
        case .warmup: "W"
        case .working(let n): "\(n)"
        }
    }

    var isWarmup: Bool {
        if case .warmup = self { return true }
        return false
    }
}
