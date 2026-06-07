import SwiftUI
import SwiftData

struct HistoryScreen: View {
    @Environment(\.theme) var theme
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(title: "History")

                    if sessions.isEmpty {
                        EmptyStateView(
                            icon: "clock.fill",
                            title: "No workouts yet",
                            message: "Every session you finish lands here \u{2014} with duration, volume and any records you set.",
                            primaryAction: ("Start a workout", { coordinator.isWorkoutActive = true })
                        )
                    } else {
                        weekStrip
                        sessionsList
                    }
                }
                .padding(.bottom, Spacing.s10)
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        let summary = ProgressEngine.computeWeekSummary(sessions: sessions)
        let days = ["M", "T", "W", "T", "F", "S", "S"]

        return VStack(spacing: Spacing.s4) {
            HStack {
                Text("This week")
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                Text("\(summary.workoutsThisWeek) of 5 planned")
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text2)
            }

            HStack {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: Spacing.s2) {
                        ZStack {
                            Circle()
                                .fill(summary.weekDays[index] ? Color.accent : theme.surface2)
                                .frame(width: 32, height: 32)
                            if summary.weekDays[index] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.onAccent)
                            }
                        }
                        Text(day)
                            .font(.system(size: TypeScale.caption, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                    if index < 6 { Spacer() }
                }
            }
        }
        .card()
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "\(sessions.count) workouts")
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s3)

            VStack(spacing: Spacing.s3) {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailScreen(session: session)) {
                        SessionCardView(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.s4)
        }
    }
}

// MARK: - Session Card

struct SessionCardView: View {
    @Environment(\.theme) var theme
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.system(size: TypeScale.callout, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text(TimeFormatter.fullDay(session.date))
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text3)
                }
                Spacer()
                if session.prCount > 0 {
                    PillView(text: "\(session.prCount) PR\(session.prCount > 1 ? "s" : "")", tone: .pr, icon: "flame.fill")
                }
            }

            HStack(spacing: Spacing.s6) {
                sessionStat("Duration", session.formattedDuration)
                sessionStat("Volume", "\(session.formattedVolume) lb")
                sessionStat("Sets", "\(session.totalSets)")
            }
            .padding(.top, Spacing.s4)
        }
        .card()
    }

    private func sessionStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: TypeScale.caption, weight: .bold))
                .foregroundStyle(theme.text3)
                .tracking(0.5)
            Text(value)
                .font(.system(size: TypeScale.callout, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.text)
        }
    }
}

// MARK: - Session Detail Screen

struct SessionDetailScreen: View {
    @Environment(\.theme) var theme
    let session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(TimeFormatter.fullDay(session.date))
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text3)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                // Stats row
                HStack(spacing: Spacing.s3) {
                    StatTileView(label: "Duration", value: session.formattedDuration)
                    StatTileView(label: "Volume", value: session.formattedVolume, unit: "lb")
                    StatTileView(label: "Sets", value: "\(session.totalSets)")
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)

                // Exercises
                SectionLabel(text: "Exercises")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: Spacing.s3) {
                    ForEach(session.sortedExercises) { sessionEx in
                        VStack(spacing: 0) {
                            // Exercise name
                            Text(sessionEx.exerciseName)
                                .font(.system(size: TypeScale.body, weight: .bold))
                                .foregroundStyle(Color.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.s4)
                                .padding(.vertical, Spacing.s3)

                            // Sets
                            ForEach(sessionEx.sortedSets) { set in
                                HStack(spacing: Spacing.s3) {
                                    Text(set.setType.label)
                                        .font(.system(size: TypeScale.body, weight: .bold))
                                        .monospacedDigit()
                                        .foregroundStyle(set.setType.isWarmup ? .warmup : theme.text2)
                                        .frame(width: 24)

                                    Text(set.displayString)
                                        .font(.system(size: TypeScale.body, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(theme.text)

                                    Spacer()

                                    if set.isPersonalRecord {
                                        PillView(text: "PR", tone: .pr, icon: "flame.fill")
                                    }
                                }
                                .padding(.horizontal, Spacing.s4)
                                .padding(.vertical, Spacing.s2)
                            }
                        }
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(theme.hairline, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, Spacing.s4)
            }
            .padding(.bottom, Spacing.s10)
        }
        .background(theme.bg)
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
