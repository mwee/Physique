import SwiftUI

struct PaywallSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .annual

    enum Plan: String, CaseIterable {
        case annual = "Annual"
        case monthly = "Monthly"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.surface2)
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.text2)
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            ScrollView {
                VStack(spacing: Spacing.s6) {
                    // Hero icon
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.accent)
                            .frame(width: 64, height: 64)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, Spacing.s4)

                    // Title & description
                    VStack(spacing: Spacing.s3) {
                        Text("Physique Pro")
                            .font(.system(size: TypeScale.title1, weight: .bold))
                            .foregroundStyle(theme.text)
                        Text("Unlock everything. Train smarter with advanced analytics, unlimited routines and full customization.")
                            .font(.system(size: TypeScale.body))
                            .foregroundStyle(theme.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.s4)
                    }

                    // Features
                    VStack(spacing: 0) {
                        featureRow(icon: "infinity", title: "Unlimited routines", subtitle: "Create and save as many custom templates as you want")
                        Divider().background(theme.hairline)
                        featureRow(icon: "chart.line.uptrend.xyaxis", title: "Every chart", subtitle: "Volume trends, e1RM tracking, bodyweight graphs and more")
                        Divider().background(theme.hairline)
                        featureRow(icon: "timer", title: "Rest-timer customization", subtitle: "Set per-exercise rest periods with auto-start")
                        Divider().background(theme.hairline)
                        featureRow(icon: "icloud.fill", title: "Cloud backup", subtitle: "Automatic sync across all your devices")
                    }
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(theme.hairline, lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.s4)

                    // Plan selection
                    VStack(spacing: Spacing.s3) {
                        planOption(
                            plan: .annual,
                            title: "Annual",
                            price: "$29.99/yr",
                            detail: "Best value \u{2014} $2.50/mo"
                        )

                        planOption(
                            plan: .monthly,
                            title: "Monthly",
                            price: "$3.99/mo",
                            detail: "Cancel anytime"
                        )
                    }
                    .padding(.horizontal, Spacing.s4)

                    // CTA button
                    Button {
                        // TODO: trigger StoreKit purchase
                    } label: {
                        Text("Start 7-day free trial")
                    }
                    .buttonStyle(.physique(.primary))
                    .padding(.horizontal, Spacing.s4)

                    // Legal
                    Text("Cancel anytime. You won\u{2019}t be charged until the trial ends.")
                        .font(.system(size: TypeScale.caption))
                        .foregroundStyle(theme.text3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.s8)
                        .padding(.bottom, Spacing.s8)
                }
            }
        }
        .background(theme.bg)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(Color.accent.opacity(0.22))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text(subtitle)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
    }

    // MARK: - Plan Option

    private func planOption(plan: Plan, title: String, price: String, detail: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPlan = plan
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text)
                    Text(detail)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                }

                Spacer()

                Text(price)
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.text)
            }
            .padding(Spacing.s4)
            .background(
                selectedPlan == plan ? Color.accent.opacity(0.12) : theme.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(
                        selectedPlan == plan ? Color.accent : theme.hairline,
                        lineWidth: selectedPlan == plan ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
