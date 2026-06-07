import SwiftUI

struct EmptyStateView: View {
    @Environment(\.theme) var theme
    let icon: String
    let title: String
    let message: String
    var primaryAction: (label: String, action: () -> Void)?
    var secondaryAction: (label: String, action: () -> Void)?

    var body: some View {
        VStack(spacing: Spacing.s5) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(theme.text3)

            VStack(spacing: Spacing.s2) {
                Text(title)
                    .font(.system(size: TypeScale.callout, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text(message)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)
            }

            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: Spacing.s3) {
                    if let primary = primaryAction {
                        Button(primary.label, action: primary.action)
                            .buttonStyle(.physique(.primary))
                    }
                    if let secondary = secondaryAction {
                        Button(secondary.label, action: secondary.action)
                            .buttonStyle(.physique(.ghost))
                    }
                }
                .padding(.top, Spacing.s2)
            }
        }
        .padding(Spacing.s8)
    }
}
