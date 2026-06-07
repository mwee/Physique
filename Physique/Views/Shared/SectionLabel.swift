import SwiftUI

struct SectionLabel: View {
    @Environment(\.theme) var theme
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: TypeScale.caption, weight: .semibold))
            .foregroundStyle(theme.text3)
            .tracking(0.8)
            .padding(.horizontal, Spacing.s5)
    }
}
