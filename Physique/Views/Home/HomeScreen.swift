import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.theme) var theme
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]
    @Query(sort: \CoachPlan.createdAt, order: .reverse) private var coachPlans: [CoachPlan]
    @Query private var exercises: [Exercise]
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query private var activePrograms: [ActiveProgram]
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]

    private var coachPlan: CoachPlan? {
        guard profiles.first?.trainingMode == "coach" else { return nil }
        return coachPlans.first
    }

    // The big four, in the order they read on the board.
    private static let bigLifts: [(id: String, name: String, short: String)] = [
        ("squat", "Back Squat", "Squat"),
        ("bench", "Bench Press", "Bench"),
        ("deadlift", "Deadlift", "Deadlift"),
        ("ohp", "Overhead Press", "Press"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(title: sessions.isEmpty ? "Welcome" : "Ready to lift")

                    liftTileGrid
                        .padding(.horizontal, Spacing.s4)

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

    // MARK: - 1RM Tiles

    private var liftTileGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s2), count: 4), spacing: Spacing.s2) {
            ForEach(Self.bigLifts, id: \.id) { lift in
                NavigationLink(destination: LiftDetailScreen(liftId: lift.id, liftName: lift.name)) {
                    liftTile(lift)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func liftTile(_ lift: (id: String, name: String, short: String)) -> some View {
        let history = LiftStatsService.history(
            liftId: lift.id, liftName: lift.name,
            entries: oneRepMaxes, sessions: sessions
        )
        let values = history.suffix(10).map(\.value)

        return VStack(spacing: Spacing.s1) {
            Text(lift.short)
                .font(.system(size: TypeScale.caption, weight: .bold))
                .foregroundStyle(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let current = LiftStatsService.currentMax(in: history) {
                Text(WeightFormatter.format(current))
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.text)
            } else {
                Text("\u{2014}")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.text3)
            }

            if values.count >= 2 {
                SparklineView(data: values, height: 18)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 18)
                    .overlay(
                        Capsule()
                            .fill(theme.surface3)
                            .frame(height: 2)
                            .padding(.horizontal, 4)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s3)
        .padding(.horizontal, Spacing.s1)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Up Next (Program)

    @ViewBuilder
    private var programUpNextCard: some View {
        if coachPlan == nil,
           let program = activePrograms.first,
           let definition = ProgramResolver.definition(for: program, customPrograms: customPrograms),
           let day = ProgramResolver.currentDay(of: definition, active: program) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accent)
                    Text("Up next")
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                        .tracking(0.5)
                    Spacer()
                    Text(ProgramResolver.weekLabel(for: program, definition: definition))
                        .font(.system(size: TypeScale.footnote, weight: .semibold))
                        .foregroundStyle(theme.text3)
                }

                Text(day.sub.map { "\(day.name) \u{00B7} \($0)" } ?? day.name)
                    .font(.system(size: TypeScale.title3, weight: .bold))
                    .foregroundStyle(theme.text)
                Text(definition.name)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)

                Button {
                    let sessionExercises = ProgramResolver.sessionExercises(
                        for: program, definition: definition, catalog: exercises
                    )
                    guard !sessionExercises.isEmpty else {
                        coordinator.selectedTab = .plan
                        return
                    }
                    coordinator.launchWorkout(
                        name: "\(definition.name) \u{00B7} \(day.name)",
                        exercises: sessionExercises,
                        advancesProgram: true
                    )
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start session")
                    }
                }
                .buttonStyle(.physique(.primary))
                .padding(.top, Spacing.s1)
            }
            .card()
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)
        }
    }

    // MARK: - Up Next (Coach)

    @ViewBuilder
    private var upNextCard: some View {
        if let plan = coachPlan {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accent)
                    Text("Up next")
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                        .tracking(0.5)
                    Spacer()
                    Text("\(CoachPlanService.daysCompletedThisWeek(plan, sessions: sessions)) of \(plan.sortedDays.count) this week")
                        .font(.system(size: TypeScale.footnote, weight: .semibold))
                        .foregroundStyle(theme.text3)
                }

                if let day = CoachPlanService.nextDay(plan, sessions: sessions) {
                    Text(day.name)
                        .font(.system(size: TypeScale.title3, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text("\(day.focus) \u{00B7} \(day.sortedExercises.count) exercises")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)

                    Button {
                        coordinator.launchWorkout(
                            name: day.name,
                            exercises: CoachPlanService.activeExercises(for: day, catalog: exercises),
                            coached: true,
                            coachPlanDayId: day.id
                        )
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start coached workout")
                        }
                    }
                    .buttonStyle(.physique(.primary))
                    .padding(.top, Spacing.s1)
                } else {
                    Text("Week complete \u{2014} nice work")
                        .font(.system(size: TypeScale.title3, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text("You\u{2019}ve finished every day in your plan this week. Rest up or repeat a session from the Plan tab.")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                }
            }
            .card()
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)
        }
    }

    // MARK: - Empty State

    private var emptyHomeContent: some View {
        VStack(spacing: Spacing.s4) {
            upNextCard
            programUpNextCard

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
            upNextCard
            programUpNextCard

            // Start workout
            Button {
                coordinator.launchBlankWorkout()
            } label: {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                    Text(coachPlan != nil ? "Start a quick workout" : "Start workout now")
                }
            }
            .buttonStyle(.physique(coachPlan != nil ? .secondary : .primary))
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
