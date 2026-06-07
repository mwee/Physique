import SwiftUI

struct CardModifier: ViewModifier {
    @Environment(\.theme) var theme
    var padding: CGFloat = Spacing.s5

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = Spacing.s5) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
