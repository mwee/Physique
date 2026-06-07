import Foundation

enum ProgramEngine {

    // MARK: - Basis Weight

    /// Returns the basis weight for calculations.
    /// For training-max programs, this is oneRM * (tmPct / 100), rounded to plate.
    /// For 1RM-based programs, the oneRM itself (rounded to plate).
    static func basisWeight(
        oneRM: Double,
        program: ProgramDefinition,
        tmPct: Int,
        unit: WeightUnit
    ) -> Double {
        switch program.basis {
        case .trainingMax:
            return roundToPlate(oneRM * Double(tmPct) / 100.0, unit: unit)
        case .oneRepMax:
            return roundToPlate(oneRM, unit: unit)
        }
    }

    // MARK: - Set Weight

    /// Calculate the weight for a single set (basis * percentage, rounded).
    static func setWeight(
        oneRM: Double,
        percentage: Double,
        program: ProgramDefinition,
        tmPct: Int,
        unit: WeightUnit
    ) -> Double {
        let basis = basisWeight(oneRM: oneRM, program: program, tmPct: tmPct, unit: unit)
        return roundToPlate(basis * percentage, unit: unit)
    }

    // MARK: - Week Scaling

    /// Scale a weight for a given week index (0-based) in waved programs.
    /// - `.multiplicative`: weight * (1 + 0.025 * week)
    /// - `.additive`: weight + (unit.increment * week)
    static func scaleForWeek(
        program: ProgramDefinition,
        weight: Double,
        week: Int,
        unit: WeightUnit
    ) -> Double {
        guard let scale = program.weekScale, week > 0 else { return weight }
        switch scale {
        case .multiplicative:
            return roundToPlate(weight * (1.0 + 0.025 * Double(week)), unit: unit)
        case .additive:
            return roundToPlate(weight + unit.increment * Double(week), unit: unit)
        }
    }

    // MARK: - Plate Rounding

    /// Round to the nearest plate-friendly increment (5 lb or 2.5 kg).
    static func roundToPlate(_ weight: Double, unit: WeightUnit) -> Double {
        let increment = unit.increment
        return (weight / increment).rounded() * increment
    }
}
