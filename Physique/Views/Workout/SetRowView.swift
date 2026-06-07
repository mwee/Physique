import SwiftUI

struct SetRowView: View {
    @Environment(\.theme) var theme
    let set: ActiveSet
    let isActive: Bool
    let activeField: ActiveWorkoutCoordinator.CellField?
    let editBuffer: String
    let onFocusWeight: () -> Void
    let onFocusReps: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            // Set type badge
            Text(set.type.label)
                .font(.system(size: TypeScale.body, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(set.type.isWarmup ? .warmup : theme.text)
                .frame(width: 30)

            // Previous
            HStack(spacing: 6) {
                Text(set.previousDisplay)
                    .font(.system(size: TypeScale.body, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(theme.text3)
                if set.isPR {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.prGold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Weight cell
            inputCell(
                value: set.weight,
                isActive: activeField == .weight,
                action: onFocusWeight
            )
            .frame(width: 62)

            // Reps cell
            inputCell(
                value: Double(set.reps),
                isActive: activeField == .reps,
                action: onFocusReps
            )
            .frame(width: 54)

            // Done checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(set.isDone ? Color.accent : theme.surface2)
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(set.isDone ? .onAccent : theme.text3)
                }
            }
            .frame(width: 38)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(height: 52)
        .background(set.isDone ? Color.accent.opacity(0.08) : Color.clear)
    }

    @ViewBuilder
    private func inputCell(value: Double, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(isActive ? Color.clear : (set.isDone ? Color.clear : theme.surface2))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .stroke(isActive ? Color.accent : Color.clear, lineWidth: 1.5)
                    )

                HStack(spacing: 1) {
                    Text(isActive ? editBuffer : displayValue(value))
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)

                    if isActive {
                        Rectangle()
                            .fill(Color.accent)
                            .frame(width: 2, height: 18)
                            .opacity(1) // Could animate blink
                    }
                }
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
    }

    private func displayValue(_ value: Double) -> String {
        if value == 0 { return "" }
        return WeightFormatter.format(value)
    }
}
