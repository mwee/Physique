import SwiftUI

struct NumericKeypad: View {
    @Environment(\.theme) var theme
    let buffer: String
    let field: ActiveWorkoutCoordinator.CellField
    let onKey: (String) -> Void
    let onNext: () -> Void
    let onClose: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            // Label row
            HStack {
                Text(field == .weight ? "Weight \u{00B7} lb" : "Reps")
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text2)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.text2)
                        .frame(width: 30, height: 30)
                        .background(theme.surface2)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s3)

            // Number grid
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { key in
                    keypadButton(key)
                }
                keypadButton(".")
                keypadButton("0")
                keypadButton("back", isIcon: true)
            }

            // Next button
            Button(action: onNext) {
                Text("Next")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(Color.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
            .padding(.top, 7)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.top, Spacing.s3)
        .padding(.bottom, Spacing.s8)
        .background(theme.surface)
        .overlay(alignment: .top) {
            Divider().background(theme.hairline)
        }
        .transition(.move(edge: .bottom))
    }

    private func keypadButton(_ key: String, isIcon: Bool = false) -> some View {
        Button {
            onKey(key)
        } label: {
            Group {
                if isIcon {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20))
                } else {
                    Text(key)
                        .font(.system(size: 23, weight: .medium))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }
}
