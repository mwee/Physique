import Foundation

enum WeightFormatter {
    /// Round to nearest plate-friendly increment
    static func roundToPlate(_ weight: Double, unit: WeightUnit) -> Double {
        let increment = unit.increment
        return (weight / increment).rounded() * increment
    }

    /// Format weight for display: "315" or "132.5"
    static func format(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }

    /// Format volume for display: "62.6k" or "850"
    static func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}
