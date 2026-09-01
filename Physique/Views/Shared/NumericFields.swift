import SwiftUI

/// Workout-style editable weight cell: tap to type, styled like the active
/// workout's input cells.
struct WeightField: View {
    @Environment(\.theme) var theme
    @Binding var value: Double
    var width: CGFloat = 72

    var body: some View {
        TextField("", value: Binding(
            get: { value },
            set: { value = max(0, $0) }
        ), format: .number)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .font(.system(size: TypeScale.body, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(theme.text)
        .frame(width: width, height: 36)
        .background(theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }
}

/// Workout-style editable reps (or any small integer) cell.
struct RepsField: View {
    @Environment(\.theme) var theme
    @Binding var value: Int
    var width: CGFloat = 60
    var range: ClosedRange<Int> = 1...100

    var body: some View {
        TextField("", value: Binding(
            get: { value },
            set: { value = min(range.upperBound, max(range.lowerBound, $0)) }
        ), format: .number)
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.system(size: TypeScale.body, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(theme.text)
        .frame(width: width, height: 36)
        .background(theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }
}
