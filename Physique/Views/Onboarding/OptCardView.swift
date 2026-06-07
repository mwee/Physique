import SwiftUI

struct OptCardView: View {
    @Environment(\.theme) var theme
    let title: String
    var subtitle: String?
    var icon: String?
    var badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s4) {
                if let icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(isSelected ? Color.accent : theme.surface2)
                            .frame(width: 42, height: 42)
                        Image(systemName: icon)
                            .font(.system(size: 19))
                            .foregroundStyle(isSelected ? .onAccent : theme.text2)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Spacing.s2) {
                        Text(title)
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)
                        if let badge {
                            PillView(text: badge, tone: .accent)
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text2)
                            .lineSpacing(2)
                    }
                }

                Spacer()

                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : theme.hairlineStrong, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.onAccent)
                    }
                }
            }
            .padding(Spacing.s4)
            .background(isSelected ? theme.accentTint : theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.accent : theme.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
