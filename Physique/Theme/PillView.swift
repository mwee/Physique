import SwiftUI

enum PillTone {
    case neutral, accent, pr, success
}

struct PillView: View {
    @Environment(\.theme) var theme
    let text: String
    var tone: PillTone = .neutral
    var icon: String?

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
        }
        .font(.system(size: TypeScale.footnote, weight: .bold))
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral: theme.surface2
        case .accent: .accent.opacity(0.22)
        case .pr: .prGold.opacity(0.16)
        case .success: .successGreen.opacity(0.16)
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .neutral: theme.text2
        case .accent: .accent
        case .pr: .prGold
        case .success: .successGreen
        }
    }
}
