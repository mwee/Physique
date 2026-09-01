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

    @State private var showBlockReview = false

    private var coachPlan: CoachPlan? {
        guard profiles.first?.trainingMode == "coach" else { return nil }
        return coachPlans.first
    }

    private var activeProgram: ActiveProgram? { activePrograms.first }

    private var activeDefinition: ProgramDefinition? {
        activeProgram.flatMap { ProgramResolver.definition(for: $0, customPrograms: customPrograms) }
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
                VStack(alignment: .leading, spacing: 0) {
                    brandHeader
                        .padding(.horizontal, Spacing.s4)

                    liftTileRow
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s4)

                    upNextSection
                        .padding(.top, Spacing.s3)

                    Button {
                        coordinator.launchBlankWorkout()
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "bolt.fill").font(.system(size: 13, weight: .semibold))
                            Text("Start empty workout")
                        }
                    }
                    .buttonStyle(.physique(sessions.isEmpty ? .primary : .ghost))
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)

                    if !sessions.isEmpty {
                        recentSection
                    }
                }
                .padding(.bottom, Spacing.s10)
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showBlockReview) {
                if let program = activeProgram, let definition = activeDefinition {
                    TrainingMaxReviewSheet(active: program, definition: definition)
                        .environment(coordinator)
                        .environment(\.theme, PhysiqueColors.dark)
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    // MARK: - Brand header (logo · wordmark · avatar, gradient rule)

    private var brandHeader: some View {
        VStack(spacing: Spacing.s3) {
            HStack {
                HStack(spacing: Spacing.s2 + 2) {
                    BrandMark(height: 24)
                    Text("Physique")
                        .font(.system(size: 22, weight: .heavy))
                        .tracking(-0.4)
                        .foregroundStyle(theme.text)
                }
                Spacer()
                NavigationLink(destination: SettingsScreen()) {
                    AvatarBubble(name: profiles.first?.displayName ?? "", size: 38)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profileBubble")
            }
            BrandRule()
        }
        .padding(.top, Spacing.s2)
    }

    // MARK: - 1RM Tiles

    private var liftTileRow: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(Self.bigLifts, id: \.id) { lift in
                NavigationLink(destination: LiftDetailScreen(liftId: lift.id, liftName: lift.name)) {
                    LiftCardView(
                        title: lift.short,
                        snapshot: LiftStatsService.snapshot(
                            liftId: lift.id, liftName: lift.name,
                            entries: oneRepMaxes, sessions: sessions
                        ),
                        fallbackValue: activeProgram?.maxes[lift.id]
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("liftTile-\(lift.id)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Up next

    @ViewBuilder
    private var upNextSection: some View {
        if let plan = coachPlan {
            coachUpNextCard(plan)
                .padding(.horizontal, Spacing.s4)
        } else if let program = activeProgram,
                  let definition = activeDefinition,
                  let day = ProgramResolver.currentDay(of: definition, active: program) {
            programUpNextCard(program: program, definition: definition, day: day)
                .padding(.horizontal, Spacing.s4)
        } else {
            noPlanCard
                .padding(.horizontal, Spacing.s4)
        }
    }

    /// Tappable card in the prototype's style: play tile · program & week ·
    /// next day · chevron, with the block status underneath.
    private func programUpNextCard(program: ActiveProgram, definition: ProgramDefinition, day: SplitDay) -> some View {
        let blockComplete = TrainingBlockService.isBlockComplete(program)
        // Day label only (e.g. "OHP / Deadlift"); the split code ("B1") is noise here.
        let dayTitle = day.sub ?? day.name

        return VStack(spacing: 0) {
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
                HStack(alignment: .center, spacing: Spacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(definition.name) \u{00B7} \(ProgramResolver.weekLabel(for: program, definition: definition))")
                            .font(.system(size: TypeScale.body, weight: .bold))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        HStack(spacing: Spacing.s2) {
                            Text(dayTitle)
                                .font(.system(size: TypeScale.footnote))
                                .foregroundStyle(theme.text2)
                                .lineLimit(1)
                            Text("NEXT UP")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.accentSoft)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer(minLength: Spacing.s2)
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Start")
                            .font(.system(size: TypeScale.sub, weight: .bold))
                    }
                    .foregroundStyle(Color.onAccent)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s2 + 2)
                    .background(Color.accent)
                    .clipShape(Capsule())
                }
                .padding(Spacing.s4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start session")

            if blockComplete {
                Divider().background(theme.accentSoft)
                Button {
                    showBlockReview = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 10, weight: .bold))
                        Text("Block complete \u{00B7} review your maxes")
                            .font(.system(size: TypeScale.footnote, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.prGold)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s2 + 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(theme.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.accentSoft, lineWidth: 1)
        )
    }

    private func coachUpNextCard(_ plan: CoachPlan) -> some View {
        let nextDay = CoachPlanService.nextDay(plan, sessions: sessions)
        let done = CoachPlanService.daysCompletedThisWeek(plan, sessions: sessions)

        return Button {
            guard let day = nextDay else { coordinator.selectedTab = .plan; return }
            coordinator.launchWorkout(
                name: day.name,
                exercises: CoachPlanService.activeExercises(for: day, catalog: exercises),
                coached: true,
                coachPlanDayId: day.id
            )
        } label: {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.accent)
                        .frame(width: 42, height: 42)
                    Image(systemName: nextDay == nil ? "checkmark" : "sparkles")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.onAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(nextDay.map { "\($0.name)" } ?? "Week complete \u{2014} nice work")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                    Text(nextDay.map { "\($0.focus) \u{00B7} \($0.sortedExercises.count) exercises \u{00B7} next up" }
                         ?? "\(done) of \(plan.sortedDays.count) done this week")
                        .font(.system(size: TypeScale.footnote))
                        .foregroundStyle(theme.text2)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.s2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accent)
            }
            .padding(Spacing.s4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(theme.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.accentSoft, lineWidth: 1)
        )
    }

    private var noPlanCard: some View {
        Button {
            coordinator.selectedTab = .plan
        } label: {
            VStack(spacing: 3) {
                Text("No active program")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
                Text("Pick a program in Plan and your sessions build themselves")
                    .font(.system(size: TypeScale.footnote))
                    .foregroundStyle(theme.text3)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.s4)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(theme.hairlineStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionLabel(text: "Recent")
                Spacer()
                Button("All history") { coordinator.selectedTab = .history }
                    .font(.system(size: TypeScale.footnote, weight: .bold))
                    .foregroundStyle(Color.accent)
                    .padding(.trailing, Spacing.s5)
            }
            .padding(.top, Spacing.s6)
            .padding(.bottom, Spacing.s3)

            VStack(spacing: 0) {
                ForEach(Array(sessions.prefix(3).enumerated()), id: \.element.id) { index, session in
                    NavigationLink(destination: SessionDetailScreen(session: session)) {
                        HStack(spacing: Spacing.s3) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 7) {
                                    Text(session.name)
                                        .font(.system(size: TypeScale.body, weight: .semibold))
                                        .foregroundStyle(theme.text)
                                        .lineLimit(1)
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
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.text3)
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                    }
                    .buttonStyle(.plain)

                    if index < min(sessions.count, 3) - 1 {
                        Divider()
                            .background(theme.hairline)
                            .padding(.leading, Spacing.s4)
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
