import SwiftUI

struct ToastData: Equatable {
    let message: String
    var icon: String?
    var tone: PillTone = .neutral
}

struct ToastModifier: ViewModifier {
    @Environment(\.theme) var theme
    let toast: ToastData?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast {
                HStack(spacing: Spacing.s2) {
                    if let icon = toast.icon {
                        Image(systemName: icon)
                            .font(.system(size: TypeScale.sub, weight: .bold))
                    }
                    Text(toast.message)
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                }
                .foregroundStyle(foregroundColor(toast.tone))
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
                .background(backgroundColor(toast.tone))
                .clipShape(RoundedRectangle(cornerRadius: Radius.full))
                .padding(.top, Spacing.s4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.25), value: toast)
    }

    private func backgroundColor(_ tone: PillTone) -> Color {
        switch tone {
        case .pr: .prGold
        case .success: .successGreen
        case .accent: .accent
        case .neutral: theme.surface3
        }
    }

    private func foregroundColor(_ tone: PillTone) -> Color {
        switch tone {
        case .pr, .success, .accent: .white
        case .neutral: theme.text
        }
    }
}

extension View {
    func toast(_ toast: ToastData?) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
