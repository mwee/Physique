import SwiftUI

/// A small "i" icon that reveals a short explainer in a popover, so helper
/// copy doesn't take up permanent vertical space next to a heading.
struct InfoPopoverButton: View {
    @Environment(\.theme) var theme
    let text: String
    var accessibilityLabel: String = "More info"
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(theme.text3)
        }
        .accessibilityLabel(accessibilityLabel)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            Text(text)
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.s4)
                .frame(maxWidth: 280, alignment: .leading)
                .presentationCompactAdaptation(.popover)
        }
    }
}
