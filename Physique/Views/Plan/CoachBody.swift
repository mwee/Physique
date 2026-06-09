import SwiftUI
import SwiftData

struct CoachBody: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator

    @Query(sort: \CoachPlan.createdAt, order: .reverse) private var plans: [CoachPlan]
    @Query private var sessions: [WorkoutSession]
    @Query private var exercises: [Exercise]
    @Query private var oneRepMaxes: [OneRepMaxEntry]
    @Query private var profiles: [UserProfile]

    @State private var service = CoachPlanService()
    @State private var freeText = ""
    @State private var chat: [(isUser: Bool, text: String)] = []
    @State private var expandedDayId: UUID?
    @State private var askedFAQs: Set<Int> = []
    @State private var isAsking = false

    private var plan: CoachPlan? { plans.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let plan {
                planContent(plan)
            } else if service.isLoading {
                buildingState
            } else {
                emptyState
            }

            askCoachSection

            Spacer().frame(height: Spacing.s10)
        }
    }

    // MARK: - Plan content

    @ViewBuilder
    private func planContent(_ plan: CoachPlan) -> some View {
        // Header
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(plan.title)
                .font(.system(size: TypeScale.title3, weight: .bold))
                .foregroundStyle(theme.text)
            Text("\(plan.daysPerWeek)-day plan \u{00B7} \(plan.goal)")
                .font(.system(size: TypeScale.sub, weight: .semibold))
                .foregroundStyle(theme.text3)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)

        // Summary rationale card
        if !plan.summary.isEmpty {
            HStack(alignment: .top, spacing: Spacing.s3) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accent)
                Text(plan.summary)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .lineSpacing(3)
            }
            .padding(Spacing.s4)
            .background(Color.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.accent.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)
        }

        // Week progress
        weekProgressHeader(plan)

        // Day cards
        VStack(spacing: Spacing.s3) {
            ForEach(plan.sortedDays) { day in
                dayCard(day, unit: plan.unit)
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s3)

        // Regenerate
        Button {
            Task { await regenerate() }
        } label: {
            HStack(spacing: Spacing.s2) {
                if service.isLoading {
                    ProgressView().tint(theme.text)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                }
                Text(service.isLoading ? "Rebuilding\u{2026}" : "Regenerate plan")
            }
        }
        .buttonStyle(.physique(.secondary))
        .disabled(service.isLoading)
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)
    }

    private func weekProgressHeader(_ plan: CoachPlan) -> some View {
        let total = plan.sortedDays.count
        let done = CoachPlanService.daysCompletedThisWeek(plan, sessions: sessions)
        return HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("This week")
                    .font(.system(size: TypeScale.caption, weight: .bold))
                    .foregroundStyle(theme.text3)
                    .tracking(0.5)
                Text("\(done) of \(total) done")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(plan.sortedDays) { day in
                    let isDone = CoachPlanService.isDoneThisWeek(day, sessions: sessions)
                    Circle()
                        .fill(isDone ? Color.accent : theme.surface2)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(theme.hairline, lineWidth: isDone ? 0 : 1)
                        )
                }
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s5)
    }

    @ViewBuilder
    private func dayCard(_ day: CoachPlanDay, unit: WeightUnit) -> some View {
        let isDone = CoachPlanService.isDoneThisWeek(day, sessions: sessions)
        let isExpanded = expandedDayId == day.id
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedDayId = isExpanded ? nil : day.id
                }
            } label: {
                HStack(spacing: Spacing.s3) {
                    ZStack {
                        Circle()
                            .fill(isDone ? Color.accent : theme.surface2)
                            .frame(width: 36, height: 36)
                        Image(systemName: isDone ? "checkmark" : "dumbbell.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isDone ? Color.onAccent : theme.text2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.name)
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)
                        Text("\(day.sortedExercises.count) exercises")
                            .font(.system(size: TypeScale.footnote))
                            .foregroundStyle(theme.text3)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.text3)
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(Array(day.sortedExercises.enumerated()), id: \.element.id) { index, ex in
                    CoachExerciseRow(exercise: ex, number: index + 1, unit: unit)
                }

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
                        Text(isDone ? "Repeat workout" : "Start coached workout")
                    }
                }
                .buttonStyle(.physique(.primary))
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
            }
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Empty / building states

    private var emptyState: some View {
        VStack(spacing: Spacing.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.accent.opacity(0.22))
                    .frame(width: 52, height: 52)
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accent)
            }
            VStack(spacing: Spacing.s2) {
                Text("No plan yet")
                    .font(.system(size: TypeScale.callout, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text("Let your coach build a weekly plan tailored to your goal, experience and equipment.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await regenerate() }
            } label: {
                Text("Generate my plan")
            }
            .buttonStyle(.physique(.primary))
        }
        .card()
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)
    }

    private var buildingState: some View {
        VStack(spacing: Spacing.s4) {
            ProgressView().tint(.accent)
            Text("Building your plan\u{2026}")
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s10)
    }

    // MARK: - Ask coach

    private var askCoachSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Ask your coach")
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s3)

            let availableFAQs = Self.faqs.enumerated().filter { !askedFAQs.contains($0.offset) }
            if !availableFAQs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(availableFAQs, id: \.offset) { index, faq in
                            Button(faq.question) {
                                askedFAQs.insert(index)
                                chat.append((true, faq.question))
                                chat.append((false, faq.answer))
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, Spacing.s2)
                            .background(theme.surface2)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
            }

            ForEach(Array(chat.enumerated()), id: \.offset) { _, msg in
                HStack {
                    if msg.isUser { Spacer() }
                    Text(msg.text)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(msg.isUser ? .onAccent : theme.text)
                        .padding(Spacing.s3)
                        .background(msg.isUser ? Color.accent : theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    if !msg.isUser { Spacer() }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s2)
            }

            HStack(spacing: Spacing.s2) {
                TextField("Ask anything\u{2026}", text: $freeText)
                    .font(.system(size: TypeScale.body))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                Button {
                    Task { await sendFreeText() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.onAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.accent)
                        .clipShape(Circle())
                }
                .disabled(isAsking || freeText.isEmpty)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s3)
        }
    }

    // MARK: - Actions

    private func sendFreeText() async {
        let question = freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, let plan else { return }
        freeText = ""
        chat.append((true, question))
        isAsking = true
        let answer = await service.ask(question, plan: plan)
        isAsking = false
        chat.append((false, answer))
    }

    private func regenerate() async {
        let profile = profiles.first
        let request = CoachPlanService.makeRequest(
            goal: profile?.goal ?? "Build muscle",
            level: profile?.experienceLevel ?? "Beginner",
            daysPerWeek: profile?.daysPerWeek ?? 4,
            equipment: profile?.equipment ?? [],
            unit: profile?.weightUnit ?? .lb,
            exercises: exercises,
            oneRepMaxes: oneRepMaxes
        )
        await service.generateAndStore(from: request, context: modelContext)
    }

    static let faqs: [(question: String, answer: String)] = [
        ("How heavy should I lift?", "Pick a weight where the last 2 reps feel genuinely hard but your form holds. If a set feels easy all the way through, nudge the weight up a little next time."),
        ("What\u{2019}s progressive overload?", "Doing a little more over time \u{2014} one more rep, a touch more weight, better control. It\u{2019}s the engine behind every result, and Physique tracks it for you automatically."),
        ("Something hurts \u{2014} what should I do?", "Sharp or joint pain means stop that movement. A working-muscle burn is normal and expected. Switch to a gentler variation if a lift bothers you."),
        ("How many days a week?", "Three to four sessions with a rest day between is plenty for most lifters \u{2014} enough to grow without burning out."),
    ]
}

// MARK: - Coach Exercise Row

struct CoachExerciseRow: View {
    @Environment(\.theme) var theme
    let exercise: CoachPlanExercise
    let number: Int
    let unit: WeightUnit
    @State private var showWhy = false

    private var detail: String {
        let repsPart = exercise.repsUnit.isEmpty ? "\(exercise.reps)" : "\(exercise.reps) \(exercise.repsUnit)"
        var s = "\(exercise.sets) \u{00D7} \(repsPart)"
        if let target = exercise.targetWeight {
            s += " @ \(WeightFormatter.format(target)) \(unit.rawValue)"
        }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.s3) {
                Text("\(number)")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(exercise.name)
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text)

                    Text(detail)
                        .font(.system(size: TypeScale.sub))
                        .monospacedDigit()
                        .foregroundStyle(theme.text2)

                    if !exercise.cue.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.accent)
                            Text(exercise.cue)
                                .font(.system(size: TypeScale.footnote))
                                .foregroundStyle(Color.accent)
                                .lineSpacing(2)
                        }
                        .padding(.top, Spacing.s1)
                    }

                    if !exercise.why.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showWhy.toggle()
                            }
                        } label: {
                            Text(showWhy ? "Hide" : "Why this?")
                                .font(.system(size: TypeScale.footnote, weight: .semibold))
                                .foregroundStyle(theme.text3)
                        }
                        .padding(.top, Spacing.s1)

                        if showWhy {
                            Text(exercise.why)
                                .font(.system(size: TypeScale.footnote))
                                .foregroundStyle(theme.text2)
                                .lineSpacing(2)
                                .padding(.top, Spacing.s1)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
        }
    }
}
