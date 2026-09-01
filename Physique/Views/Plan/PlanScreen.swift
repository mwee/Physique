import SwiftUI
import SwiftData

/// The self-guided plan: one multi-week **program** (sessions generated from
/// locked training maxes) plus any number of single-workout **templates**.
struct PlanScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator
    @Query private var activePrograms: [ActiveProgram]
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var profiles: [UserProfile]
    @Query private var exerciseCatalog: [Exercise]

    @State private var selectedMode: PlanMode?
    @State private var showBlockReview = false

    enum PlanMode: String, CaseIterable {
        case plan = "My Plan"
        case coach = "AI Coach"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Plan")

                modeToggle
                    .padding(.horizontal, Spacing.s4)

                ScrollView {
                    switch resolvedMode {
                    case .plan:
                        planBody
                    case .coach:
                        CoachBody()
                    }
                }
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if selectedMode == nil {
                    selectedMode = profiles.first?.trainingMode == "coach" ? .coach : .plan
                }
            }
            .onChange(of: profiles.first?.trainingMode) { _, newMode in
                selectedMode = newMode == "coach" ? .coach : .plan
            }
            .sheet(isPresented: $showBlockReview) {
                if let program = activePrograms.first,
                   let definition = ProgramResolver.definition(for: program, customPrograms: customPrograms) {
                    TrainingMaxReviewSheet(active: program, definition: definition)
                        .environment(coordinator)
                        .environment(\.theme, PhysiqueColors.dark)
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private var resolvedMode: PlanMode {
        selectedMode ?? (profiles.first?.trainingMode == "coach" ? .coach : .plan)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(PlanMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                        .foregroundStyle(resolvedMode == mode ? theme.text : theme.text3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s3)
                        .background(resolvedMode == mode ? theme.surface2 : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s1)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Plan body

    private var planBody: some View {
        VStack(spacing: 0) {
            programSection
            templatesSection
            Spacer().frame(height: Spacing.s10)
        }
    }

    /// Section heading with an icon, a kind pill and a one-line explainer so
    /// programs and templates read as clearly different things.
    private func sectionHeader(icon: String, title: String, kind: String, tone: PillTone, blurb: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(spacing: Spacing.s2) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tone == .accent ? Color.accent : theme.text2)
                Text(title.uppercased())
                    .font(.system(size: TypeScale.caption, weight: .semibold))
                    .foregroundStyle(theme.text3)
                    .tracking(0.8)
                PillView(text: kind, tone: tone)
                Spacer()
            }
            Text(blurb)
                .font(.system(size: TypeScale.footnote))
                .foregroundStyle(theme.text3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.s5)
    }

    // MARK: - Program section

    private var programSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "calendar.badge.clock",
                title: "Program",
                kind: "Multi-week",
                tone: .accent,
                blurb: "One at a time. Each session is generated from training maxes that stay locked for the block."
            )
            .padding(.top, Spacing.s5)
            .padding(.bottom, Spacing.s3)

            if let program = activePrograms.first {
                activeProgramCard(program)
                    .padding(.horizontal, Spacing.s4)
            } else {
                emptyProgramState
                    .padding(.horizontal, Spacing.s4)
            }

            NavigationLink(destination: LibraryBrowseScreen()) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 14))
                    Text(activePrograms.isEmpty ? "Browse programs" : "Browse programs")
                }
            }
            .buttonStyle(.physique(.secondary))
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s3)
        }
    }

    private var emptyProgramState: some View {
        VStack(spacing: Spacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Color.accent.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accent)
            }
            VStack(spacing: Spacing.s1) {
                Text("No active program")
                    .font(.system(size: TypeScale.callout, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text("Pick a proven program or build your own in %TM. Your 1RMs fill in the numbers.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.s5)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.hairlineStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
        )
    }

    @ViewBuilder
    private func activeProgramCard(_ program: ActiveProgram) -> some View {
        if let definition = ProgramResolver.definition(for: program, customPrograms: customPrograms),
           let day = ProgramResolver.currentDay(of: definition, active: program) {
            nextSessionCard(program: program, definition: definition, day: day)
        } else {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Program unavailable")
                    .font(.system(size: TypeScale.callout, weight: .bold))
                    .foregroundStyle(theme.text)
                Text("The active program couldn\u{2019}t be loaded. Pick a new one from the library.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
            .contextMenu {
                Button(role: .destructive) {
                    modelContext.delete(program)
                    try? modelContext.save()
                } label: {
                    Label("Deactivate program", systemImage: "xmark.circle")
                }
            }
        }
    }

    private func nextSessionCard(program: ActiveProgram, definition: ProgramDefinition, day: SplitDay) -> some View {
        let exercises = ProgramResolver.sessionExercises(for: program, definition: definition, catalog: exerciseCatalog)
        let blockComplete = TrainingBlockService.isBlockComplete(program)

        return VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(definition.name) \u{00B7} \(ProgramResolver.weekLabel(for: program, definition: definition))")
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                        .tracking(0.5)
                    Text(day.sub.map { "\(day.name) \u{00B7} \($0)" } ?? day.name)
                        .font(.system(size: TypeScale.title3, weight: .bold))
                        .foregroundStyle(theme.text)
                }
                Spacer()
                PillView(text: "Active", tone: .success, icon: "checkmark")
            }

            // Block status + progress
            VStack(alignment: .leading, spacing: Spacing.s1) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: blockComplete ? "flag.checkered" : "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(blockComplete
                         ? "Block complete \u{00B7} review your maxes"
                         : "Block \u{00B7} \(TrainingBlockService.blockLabel(program)) \u{00B7} maxes locked")
                        .font(.system(size: TypeScale.footnote, weight: .semibold))
                }
                .foregroundStyle(blockComplete ? Color.prGold : theme.text2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.surface3)
                        Capsule()
                            .fill(blockComplete ? Color.prGold : Color.accent)
                            .frame(width: geo.size.width * TrainingBlockService.blockProgress(program))
                    }
                }
                .frame(height: 4)
            }

            if blockComplete {
                Button {
                    showBlockReview = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                        Text("Review training maxes")
                    }
                    .font(.system(size: TypeScale.sub, weight: .bold))
                    .foregroundStyle(Color.prGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s3)
                    .background(Color.prSoft)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
                .buttonStyle(.plain)
            }

            // Session rows with computed weights
            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    let working = exercise.sets.filter { !$0.type.isWarmup }
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(exercise.name)
                                .font(.system(size: TypeScale.body, weight: .semibold))
                                .foregroundStyle(theme.text)
                            Text(schemeLabel(for: working))
                                .font(.system(size: TypeScale.footnote, weight: .semibold))
                                .foregroundStyle(theme.text3)
                        }

                        Spacer()

                        if let top = working.map(\.weight).max(), top > 0 {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(WeightFormatter.format(top))
                                    .font(.system(size: TypeScale.callout, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.text)
                                Text(program.unit.displayName)
                                    .font(.system(size: TypeScale.caption, weight: .bold))
                                    .foregroundStyle(theme.text3)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.s2)

                    if index < exercises.count - 1 {
                        Divider().background(theme.hairline)
                    }
                }
            }

            Button {
                startProgramSession(program: program, definition: definition, day: day, exercises: exercises)
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
        .padding(Spacing.s5)
        .background(theme.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.accentSoft, lineWidth: 1)
        )
        .contextMenu {
            Button {
                showBlockReview = true
            } label: {
                Label("Update training maxes", systemImage: "lock.open")
            }
            Button {
                ProgramResolver.advance(program, definition: definition)
                try? modelContext.save()
            } label: {
                Label("Skip this day", systemImage: "forward.fill")
            }
            Button(role: .destructive) {
                modelContext.delete(program)
                try? modelContext.save()
            } label: {
                Label("Deactivate program", systemImage: "xmark.circle")
            }
        }
    }

    /// "3 × 5" for straight sets, "3 sets · top set" for ramps.
    private func schemeLabel(for working: [ActiveSet]) -> String {
        guard let first = working.first else { return "" }
        let uniform = working.allSatisfy { $0.reps == first.reps && $0.weight == first.weight }
        if uniform {
            return "\(working.count) \u{00D7} \(first.reps)"
        }
        return "\(working.count) sets \u{00B7} top set"
    }

    private func startProgramSession(program: ActiveProgram, definition: ProgramDefinition, day: SplitDay, exercises: [ActiveExercise]) {
        guard !exercises.isEmpty else {
            coordinator.showToast("Set your maxes to build this session", icon: "exclamationmark.triangle")
            return
        }
        coordinator.launchWorkout(
            name: "\(definition.name) \u{00B7} \(day.name)",
            exercises: exercises,
            advancesProgram: true
        )
    }

    // MARK: - Templates section

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "doc.text",
                title: "Templates",
                kind: "Single workouts",
                tone: .neutral,
                blurb: "Reusable workouts with fixed sets, reps and weights. Start one any time \u{2014} they don\u{2019}t touch your program."
            )
            .padding(.top, Spacing.s8)
            .padding(.bottom, Spacing.s3)

            if templates.isEmpty {
                Text("No templates yet. Build one from scratch, or save a day from any program.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text3)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.s5)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    )
                    .padding(.horizontal, Spacing.s4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                        templateRow(template)
                        if index < templates.count - 1 {
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

            NavigationLink(destination: TemplateEditorScreen()) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New template")
                }
            }
            .buttonStyle(.physique(.ghost))
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s3)
        }
    }

    /// Tapping the row opens the template to view/edit; the Start pill runs it.
    private func templateRow(_ template: WorkoutTemplate) -> some View {
        NavigationLink(destination: templateDestination(template)) {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    Circle()
                        .fill(theme.surface2)
                        .frame(width: 38, height: 38)
                    Image(systemName: template.kind == .program ? "calendar.day.timeline.left" : "doc.text")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.text2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text)
                    Text(templateSubtitle(template))
                        .font(.system(size: TypeScale.footnote))
                        .foregroundStyle(theme.text3)
                }

                Spacer()

                Button {
                    startTemplate(template)
                } label: {
                    Text("Start")
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                        .foregroundStyle(Color.onAccent)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s2)
                        .background(Color.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.text3)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func templateSubtitle(_ template: WorkoutTemplate) -> String {
        let count = TemplateService.exercises(from: template).count
        let exercises = "\(count) exercise\(count == 1 ? "" : "s")"
        switch template.kind {
        case .program:
            let programName = template.programId.flatMap { BuiltInPrograms.find($0)?.name } ?? "program"
            return "\(exercises) \u{00B7} from \(programName) \u{00B7} tap to edit"
        case .custom:
            return "\(exercises) \u{00B7} tap to edit"
        }
    }

    private func templateDestination(_ template: WorkoutTemplate) -> some View {
        TemplateEditorScreen(existing: template)
    }

    private func startTemplate(_ template: WorkoutTemplate) {
        let exercises = TemplateService.exercises(from: template)
        guard !exercises.isEmpty else {
            coordinator.showToast("This template has no exercises", icon: "exclamationmark.triangle")
            return
        }
        coordinator.launchWorkout(name: template.name, exercises: exercises)
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }
}
