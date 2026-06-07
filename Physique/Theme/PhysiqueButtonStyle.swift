import SwiftUI

enum ButtonVariant {
    case primary, secondary, ghost, destructive, success
}

struct PhysiqueButtonStyle: ButtonStyle {
    @Environment(\.theme) var theme
    let variant: ButtonVariant
    var fullWidth: Bool = true
    var size: ButtonSize = .md

    enum ButtonSize {
        case sm, md
        var fontSize: CGFloat {
            switch self {
            case .sm: 14
            case .md: 16
            }
        }
        var verticalPadding: CGFloat {
            switch self {
            case .sm: 9
            case .md: 14
            }
        }
        var horizontalPadding: CGFloat {
            switch self {
            case .sm: 14
            case .md: 20
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold))
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: .accent
        case .secondary: .accent.opacity(0.22)
        case .ghost: theme.surface2
        case .destructive: .dangerRed.opacity(0.14)
        case .success: .successGreen
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .onAccent
        case .secondary: .accent
        case .ghost: theme.text
        case .destructive: .dangerRed
        case .success: .white
        }
    }
}

extension ButtonStyle where Self == PhysiqueButtonStyle {
    static func physique(_ variant: ButtonVariant, fullWidth: Bool = true, size: PhysiqueButtonStyle.ButtonSize = .md) -> PhysiqueButtonStyle {
        PhysiqueButtonStyle(variant: variant, fullWidth: fullWidth, size: size)
    }
}
