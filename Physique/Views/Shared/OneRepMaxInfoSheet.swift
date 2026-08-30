import SwiftUI

/// Explains what a 1RM is and how the app estimates it.
struct OneRepMaxInfoSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    infoCard(
                        icon: "trophy.fill",
                        title: "What is a 1RM?",
                        text: "Your one-rep max is the heaviest weight you could lift for a single rep with good form. It's the standard measure of strength on a lift."
                    )

                    infoCard(
                        icon: "function",
                        title: "Why \u{201C}estimated\u{201D}?",
                        text: "You don't need to test your true max \u{2014} that's taxing and risky to do often. Instead, every set you log is converted into an estimate (e1RM) using the Epley formula:"
                    ) {
                        VStack(spacing: Spacing.s2) {
                            Text("e1RM = weight \u{00D7} (1 + reps \u{00F7} 30)")
                                .font(.system(size: TypeScale.body, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(theme.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.s3)
                                .background(theme.surface2)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                            Text("Example: 200 lb \u{00D7} 5 reps \u{2248} 233 lb e1RM")
                                .font(.system(size: TypeScale.sub))
                                .foregroundStyle(theme.text2)
                        }
                        .padding(.top, Spacing.s3)
                    }

                    infoCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "How to use it",
                        text: "Watch the trend, not single data points. A rising e1RM means you're getting stronger \u{2014} even when you never train near your max. Estimates are most accurate for sets under 10 reps."
                    )
                }
                .padding(Spacing.s4)
            }
            .background(theme.bg)
            .navigationTitle("Estimated 1RM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.text2)
                    }
                }
            }
        }
    }

    private func infoCard(
        icon: String,
        title: String,
        text: String,
        @ViewBuilder extra: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Text(title)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
            }
            Text(text)
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
                .lineSpacing(3)
            extra()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
