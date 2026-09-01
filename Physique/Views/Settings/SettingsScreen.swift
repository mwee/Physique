import SwiftUI
import SwiftData

/// Profile + training-math settings, reached from the avatar bubble on Home.
struct SettingsScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]

    @State private var name: String = ""

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                profileCard
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                SectionLabel(text: "Training math")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: 0) {
                    settingRow("Units", first: true) {
                        segmented(options: [(WeightUnit.lb, "lb"), (WeightUnit.kg, "kg")],
                                  selected: profile?.weightUnit ?? .lb) { unit in
                            profile?.weightUnit = unit
                            persist()
                        }
                    }
                    settingRow("TM default") {
                        segmented(options: [(85, "85%"), (90, "90%"), (95, "95%")],
                                  selected: profile?.defaultTrainingMaxPercent ?? 90) { pct in
                            profile?.defaultTrainingMaxPercent = pct
                            persist()
                        }
                    }
                    settingRow("e1RM formula") {
                        Text("Epley")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                }
                .groupedCard()
                .padding(.horizontal, Spacing.s4)

                Text("Training maxes are locked for each program block. New programs start at your 1RM \u{00D7} TM default.")
                    .font(.system(size: TypeScale.footnote))
                    .foregroundStyle(theme.text3)
                    .padding(.horizontal, Spacing.s5)
                    .padding(.top, Spacing.s2)

                SectionLabel(text: "Plan")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: 0) {
                    settingRow("Training mode", first: true) {
                        segmented(options: [("template", "Self-guided"), ("coach", "AI Coach")],
                                  selected: profile?.trainingMode ?? "template") { mode in
                            profile?.trainingMode = mode
                            persist()
                        }
                    }
                    settingRow("Days per week") {
                        Text("\(profile?.daysPerWeek ?? 4)")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(theme.text3)
                    }
                }
                .groupedCard()
                .padding(.horizontal, Spacing.s4)

                SectionLabel(text: "About")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: 0) {
                    settingRow("Version", first: true) {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                }
                .groupedCard()
                .padding(.horizontal, Spacing.s4)

                Spacer().frame(height: Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = profile?.displayName ?? "" }
        .onChange(of: name) { _, newValue in
            guard let profile, profile.displayName != newValue else { return }
            profile.displayName = newValue
            persist()
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        HStack(spacing: Spacing.s3) {
            AvatarBubble(name: name, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                TextField("Your name", text: $name)
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
                    .textInputAutocapitalization(.words)
                Text(profileSubtitle)
                    .font(.system(size: TypeScale.footnote))
                    .foregroundStyle(theme.text3)
            }
            Spacer()
            Image(systemName: "pencil")
                .font(.system(size: 14))
                .foregroundStyle(theme.text3)
        }
        .card(padding: Spacing.s4)
    }

    private var profileSubtitle: String {
        var parts: [String] = []
        if let bw = bodyweightEntries.first {
            parts.append("BW \(WeightFormatter.format(bw.weight)) \(bw.unit.displayName)")
        }
        if let created = profile?.createdAt {
            parts.append("since \(Calendar.current.component(.year, from: created))")
        }
        return parts.isEmpty ? "Tap to add your name" : parts.joined(separator: " \u{00B7} ")
    }

    // MARK: - Rows

    private func settingRow<Trailing: View>(_ label: String, first: Bool = false, @ViewBuilder trailing: () -> Trailing) -> some View {
        VStack(spacing: 0) {
            if !first {
                Divider().background(theme.hairline).padding(.leading, Spacing.s4)
            }
            HStack {
                Text(label)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                trailing()
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
        }
    }

    private func segmented<T: Hashable>(options: [(T, String)], selected: T, onSelect: @escaping (T) -> Void) -> some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { value, label in
                Button(label) { onSelect(value) }
                    .font(.system(size: TypeScale.footnote, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(value == selected ? .onAccent : theme.text2)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(value == selected ? Color.accent : theme.surface2)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
    }

    private func persist() {
        try? modelContext.save()
    }
}

// MARK: - Grouped card helper

private struct GroupedCardModifier: ViewModifier {
    @Environment(\.theme) var theme
    func body(content: Content) -> some View {
        content
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(theme.hairline, lineWidth: 1))
    }
}

extension View {
    /// Surface + hairline container for stacked setting/list rows (no inner padding).
    func groupedCard() -> some View { modifier(GroupedCardModifier()) }
}
