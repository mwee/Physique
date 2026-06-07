import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.theme) var theme
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(title: sessions.isEmpty ? "Welcome" : "Ready to lift")

                    if sessions.isEmpty {
                        emptyHomeContent
                    } else {
                        populatedHomeContent
                    }
                }
                .padding(.bottom, Spacing.s10)
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Empty State

    private var emptyHomeContent: some View {
        VStack(spacing: Spacing.s4) {
            // Hero card
            VStack(spacing: Spacing.s4) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.accent.opacity(0.22))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accent)
                }

                Text("Let\u{2019}s log your first lift")
                    .font(.system(size: TypeScale.title3, weight: .bold))
                    .foregroundStyle(theme.text)

                Text("Start a session and Physique begins tracking your strength, volume and records automatically.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)

                VStack(spacing: Spacing.s3) {
                    Button {
                        coordinator.launchBlankWorkout()
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                            Text("Start workout now")
                        }
                    }
                    .buttonStyle(.physique(.primary))

                    Button {
                        coordinator.selectedTab = .plan
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "clipboard.fill")
                                .font(.system(size: 14))
                            Text("Browse templates")
                        }
                    }
                    .buttonStyle(.physique(.ghost))
                }
                .padding(.top, Spacing.s2)
            }
            .card()
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            // Empty stats
            SectionLabel(text: "Your week")
                .padding(.top, Spacing.s4)

            HStack(spacing: Spacing.s3) {
                emptyStatTile("Streak", icon: "flame.fill")
                emptyStatTile("Workouts", icon: "dumbbell.fill")
                emptyStatTile("Volume", icon: "chart.bar.fill")
            }
            .padding(.horizontal, Spacing.s4)
        }
    }

    private func emptyStatTile(_ label: String, icon: String) -> some View {
        VStack(spacing: Spacing.s2) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(theme.text3)
            Text("\u{2014}")
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.text3)
            Text(label.uppercased())
                .font(.system(size: TypeScale.caption, weight: .semibold))
                .foregroundStyle(theme.text3)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s4)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
        )
    }

    // MARK: - Populated State

    private var populatedHomeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Start workout
            Button {
                coordinator.launchBlankWorkout()
            } label: {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text("Start workout now")
                }
            }
            .buttonStyle(.physique(.primary))
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            // Quick stats
            let summary = ProgressEngine.computeWeekSummary(sessions: sessions)
            HStack(spacing: Spacing.s3) {
                StatTileView(label: "Streak", value: "\(summary.streakWeeks)", unit: "wk", icon: "flame.fill")
                StatTileView(label: "This week", value: "\(summary.workoutsThisWeek)", unit: "lifts", icon: "dumbbell.fill")
                StatTileView(label: "Volume", value: WeightFormatter.formatVolume(summary.weeklyVolume), icon: "chart.bar.fill")
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            // Recent sessions
            SectionLabel(text: "Recent")
                .padding(.top, Spacing.s5)
                .padding(.bottom, Spacing.s3)

            VStack(spacing: 0) {
                ForEach(Array(sessions.prefix(3).enumerated()), id: \.element.id) { index, session in
                    NavigationLink(destination: SessionDetailScreen(session: session)) {
                        HStack(spacing: Spacing.s3) {
                            ZStack {
                                RoundedRectangle(cornerRadius: Radius.xs)
                                    .fill(theme.surface2)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(theme.text2)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 7) {
                                    Text(session.name)
                                        .font(.system(size: TypeScale.body, weight: .semibold))
                                        .foregroundStyle(theme.text)
                                    if session.prCount > 0 {
                                        PillView(text: "\(session.prCount)", tone: .pr, icon: "flame.fill")
                                    }
                                }
                                Text("\(TimeFormatter.relativeDay(session.date)) \u{00B7} \(session.formattedDuration) \u{00B7} \(session.formattedVolume) lb")
                                    .font(.system(size: TypeScale.footnote))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.text3)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(theme.text3)
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                    }
                    .buttonStyle(.plain)

                    if index < min(sessions.count, 3) - 1 {
                        Divider()
                            .background(theme.hairline)
                            .padding(.leading, 62)
                    }
                }
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(theme.hairline, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.s4)
        }
    }
}
