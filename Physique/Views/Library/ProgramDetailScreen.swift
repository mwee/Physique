import SwiftUI
import SwiftData

struct ProgramDetailScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]
    @Query private var activePrograms: [ActiveProgram]

    let program: ProgramDefinition
    /// Seed values when opened from a saved program template.
    var initialMaxes: [String: Double]? = nil
    var initialTMPct: Int? = nil

    @State private var maxes: [String: Double] = [:]
    @State private var tmPct: Int = 90
    @State private var blockWeeks: Int = 6
    @State private var includeWarmups: Bool = false
    @State private var unit: WeightUnit = .lb
    @State private var expandedDay: Int?
    @State private var configured = false

    private var isCustom: Bool { program.id.hasPrefix("custom-") }

    private var customProgram: CustomProgram? {
        customPrograms.first { $0.programId == program.id }
    }

    /// Custom programs are read live so edits made in the builder show up
    /// when the user pops back here.
    private var resolvedProgram: ProgramDefinition {
        customProgram?.definition(forWeek: 0) ?? program
    }

    private var isActive: Bool {
        activePrograms.first?.programId == program.id
    }

    var body: some View {
        let program = resolvedProgram

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: Spacing.s4) {
                    ProgramGlyph(text: program.glyph, size: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(program.name)
                            .font(.system(size: TypeScale.title2, weight: .bold))
                            .foregroundStyle(theme.text)
                        Text(program.author)
                            .font(.system(size: TypeScale.body))
                            .foregroundStyle(theme.text2)
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)

                // Tags + meta (wraps to a second row when needed)
                FlowLayout {
                    PillView(text: "Program", tone: .accent, icon: "calendar.badge.clock")
                    ForEach(program.tags, id: \.self) { tag in
                        PillView(text: tag, tone: .neutral)
                    }
                    PillView(text: program.days, tone: .neutral)
                    PillView(text: program.cycle, tone: .neutral)
                    if isActive {
                        PillView(text: "Active", tone: .success, icon: "checkmark")
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s3)

                // Blurb
                Text(program.blurb)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .lineSpacing(3)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                // Maxes
                SectionLabel(text: "Your maxes")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: Spacing.s3) {
                    ForEach(program.liftIds, id: \.self) { liftId in
                        maxRow(liftId, program: program)
                    }
                }

                // TM% for programs that use it
                if program.basis == .trainingMax {
                    SectionLabel(text: "Training Max")
                        .padding(.top, Spacing.s6)
                        .padding(.bottom, Spacing.s3)

                    HStack(spacing: Spacing.s3) {
                        ForEach([85, 90, 95], id: \.self) { pct in
                            Button("\(pct)%") {
                                tmPct = pct
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(tmPct == pct ? .onAccent : theme.text2)
                            .padding(.horizontal, Spacing.s4)
                            .padding(.vertical, Spacing.s2)
                            .background(tmPct == pct ? Color.accent : theme.surface2)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }

                // Training block
                SectionLabel(text: "Training block")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                blockSection(program: program)
                    .padding(.horizontal, Spacing.s4)

                // Week 1 preview
                SectionLabel(text: "Week 1 \u{00B7} with your maxes")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                weekOnePreview(program: program)
                    .padding(.horizontal, Spacing.s4)

                // Progression note
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accent)
                        Text("How it progresses")
                            .font(.system(size: TypeScale.sub, weight: .bold))
                            .foregroundStyle(theme.text)
                    }
                    Text(program.progressNote)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                        .lineSpacing(2)
                }
                .card()
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

                Spacer(minLength: 100)
            }
            .padding(.bottom, Spacing.s10)
        }
        .background(theme.bg)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Spacing.s2) {
                Button {
                    activateProgram(program)
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "lock.fill").font(.system(size: 13))
                        Text(isActive ? "Restart this program" : "Use this program")
                    }
                }
                .buttonStyle(.physique(.primary))

                if let custom = customProgram {
                    NavigationLink(destination: ProgramBuilderScreen(existing: custom)) {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "square.and.pencil").font(.system(size: 14))
                            Text("Edit program")
                        }
                    }
                    .buttonStyle(.physique(.secondary))
                } else if !isCustom {
                    Menu {
                        ForEach(Array(program.split.enumerated()), id: \.element.id) { index, day in
                            Button {
                                saveDayAsTemplate(index, day: day, program: program)
                            } label: {
                                Label(day.sub.map { "\(day.name) \u{00B7} \($0)" } ?? day.name, systemImage: "doc.text")
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "doc.text").font(.system(size: 14))
                            Text("Save a day as a template")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accent.opacity(0.22))
                        .foregroundStyle(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s4)
            .background(.ultraThinMaterial)
        }
        .onAppear { configure(program) }
    }

    // MARK: - Setup

    private func configure(_ program: ProgramDefinition) {
        guard !configured else { return }
        configured = true
        unit = profiles.first?.weightUnit ?? .lb
        tmPct = initialTMPct ?? profiles.first?.defaultTrainingMaxPercent ?? 90
        blockWeeks = isCustom ? program.cycleWeeks : TrainingBlockService.defaultBlockWeeks(for: program)
        for liftId in program.liftIds where maxes[liftId] == nil {
            if let seeded = initialMaxes?[liftId], seeded > 0 {
                maxes[liftId] = seeded
            } else {
                maxes[liftId] = defaultMax(liftId)
            }
        }
    }

    // MARK: - Max row

    private func maxRow(_ liftId: String, program: ProgramDefinition) -> some View {
        let liftName = ExerciseCatalog.displayName(for: liftId)
        let value = maxes[liftId, default: defaultMax(liftId)]
        let fromHistory = calculatedMax(liftId, name: liftName)

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(liftName)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                HStack(spacing: 4) {
                    Image(systemName: fromHistory != nil ? "chart.line.uptrend.xyaxis" : "questionmark.circle")
                        .font(.system(size: 9, weight: .bold))
                    Text(maxCaption(value: value, fromHistory: fromHistory != nil, program: program))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .font(.system(size: TypeScale.caption, weight: .semibold))
                .foregroundStyle(theme.text3)
            }

            Spacer()

            HStack(spacing: Spacing.s2) {
                Button {
                    maxes[liftId, default: defaultMax(liftId)] -= unit.increment
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.text)
                        .frame(width: 32, height: 32)
                        .background(theme.surface2)
                        .clipShape(Circle())
                }

                HStack(spacing: 4) {
                    WeightField(value: Binding(
                        get: { maxes[liftId, default: defaultMax(liftId)] },
                        set: { maxes[liftId] = max(0, $0) }
                    ), width: 64)
                    Text(unit.rawValue)
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                }

                Button {
                    maxes[liftId, default: defaultMax(liftId)] += unit.increment
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.onAccent)
                        .frame(width: 32, height: 32)
                        .background(Color.accent)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.s4)
    }

    private func maxCaption(value: Double, fromHistory: Bool, program: ProgramDefinition) -> String {
        var parts = [fromHistory ? "From your 1RM" : "Default"]
        if program.basis == .trainingMax {
            let tm = ProgramEngine.basisWeight(oneRM: value, program: program, tmPct: tmPct, unit: unit)
            parts.append("TM \(WeightFormatter.format(tm))")
        }
        return parts.joined(separator: " \u{00B7} ")
    }

    // MARK: - Block

    private func blockSection(program: ProgramDefinition) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if isCustom {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accent)
                    Text("\(program.cycleWeeks)-week block")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text("\u{00B7} set in the builder")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text3)
                }
            } else {
                HStack(spacing: Spacing.s2) {
                    ForEach(TrainingBlockService.blockOptions(for: program), id: \.self) { weeks in
                        Button {
                            blockWeeks = weeks
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(weeks) weeks")
                                    .font(.system(size: TypeScale.sub, weight: .bold))
                                if weeks == program.cycleWeeks {
                                    Text("1 cycle")
                                        .font(.system(size: TypeScale.caption, weight: .semibold))
                                        .opacity(0.8)
                                }
                            }
                            .foregroundStyle(blockWeeks == weeks ? .onAccent : theme.text2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s2)
                            .background(blockWeeks == weeks ? Color.accent : theme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text("Your maxes lock when you activate and every session is built from them. At the end of the block Physique compares them with what you actually lifted and suggests new ones.")
                .font(.system(size: TypeScale.footnote))
                .foregroundStyle(theme.text3)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Spacing.s4)
    }

    // MARK: - Week 1 Preview

    private func weekOnePreview(program: ProgramDefinition) -> some View {
        // Not inserted into the context — just a throwaway config for the builder.
        let config = ActiveProgram(
            programId: program.id,
            maxes: maxes,
            trainingMaxPercent: tmPct,
            includeWarmups: false,
            currentWeek: 0,
            unit: unit
        )

        return VStack(spacing: 0) {
            ForEach(Array(program.split.enumerated()), id: \.element.id) { index, day in
                let isOpen = expandedDay == index
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            expandedDay = isOpen ? nil : index
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(day.name)
                                    .font(.system(size: TypeScale.body, weight: .bold))
                                    .foregroundStyle(theme.text)
                                if !isOpen, let summary = daySummary(day, program: program) {
                                    Text(summary)
                                        .font(.system(size: TypeScale.footnote))
                                        .foregroundStyle(theme.text2)
                                }
                            }
                            Spacer()
                            Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.text3)
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if isOpen {
                        let dayExercises = SessionBuilder.buildSession(program: program, config: config, dayIndex: index)
                        VStack(spacing: 0) {
                            ForEach(dayExercises) { exercise in
                                let working = exercise.sets.filter { !$0.type.isWarmup }
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(exercise.name)
                                            .font(.system(size: TypeScale.sub, weight: .semibold))
                                            .foregroundStyle(theme.text)
                                        if let first = working.first {
                                            Text("\(working.count) \u{00D7} \(first.reps)")
                                                .font(.system(size: TypeScale.caption, weight: .semibold))
                                                .foregroundStyle(theme.text3)
                                        }
                                    }
                                    Spacer()
                                    if let top = working.map(\.weight).max(), top > 0 {
                                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                                            Text(WeightFormatter.format(top))
                                                .font(.system(size: TypeScale.body, weight: .bold))
                                                .monospacedDigit()
                                                .foregroundStyle(theme.text)
                                            Text(unit.displayName)
                                                .font(.system(size: TypeScale.caption, weight: .bold))
                                                .foregroundStyle(theme.text3)
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.s4)
                                .padding(.vertical, Spacing.s2)
                            }
                        }
                        .padding(.bottom, Spacing.s2)
                    }
                }

                if index < program.split.count - 1 {
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
    }

    /// Collapsed one-liner: lift names trained that day.
    private func daySummary(_ day: SplitDay, program: ProgramDefinition) -> String? {
        var liftIds: [String] = []
        if let items = day.items {
            liftIds = items.map(\.id)
        } else if !day.ids.isEmpty {
            liftIds = day.ids
        } else if program.single {
            liftIds = program.liftIds
        }
        guard !liftIds.isEmpty else { return day.sub }
        return liftIds.map { ExerciseCatalog.shortName(for: $0) }.joined(separator: " \u{00B7} ")
    }

    // MARK: - 1RM sources

    private func calculatedMax(_ liftId: String, name: String) -> Double? {
        let history = LiftStatsService.history(liftId: liftId, liftName: name, entries: oneRepMaxes, sessions: sessions)
        return LiftStatsService.currentMax(in: history)
    }

    /// Prefer the user's current 1RM (tested or calculated from workouts);
    /// fall back to the program's built-in default, then a conservative bar.
    private func defaultMax(_ liftId: String) -> Double {
        if let current = calculatedMax(liftId, name: ExerciseCatalog.displayName(for: liftId)) {
            return WeightFormatter.roundToPlate(current, unit: unit)
        }
        if let builtIn = BuiltInPrograms.defaults[unit]?[liftId] { return builtIn }
        return unit == .lb ? 95 : 40
    }

    // MARK: - Actions

    private func activateProgram(_ program: ProgramDefinition) {
        let descriptor = FetchDescriptor<ActiveProgram>()
        if let existing = try? modelContext.fetch(descriptor) {
            for p in existing { modelContext.delete(p) }
        }

        let active = ActiveProgram(
            programId: program.id,
            maxes: maxes,
            trainingMaxPercent: tmPct,
            includeWarmups: includeWarmups,
            unit: unit,
            blockWeeks: max(1, blockWeeks)
        )
        active.maxesLog = [MaxesSnapshot(date: Date(), maxes: maxes)]
        modelContext.insert(active)

        // The max the lifter states at setup is a real data point: feed it into
        // the e1RM stream for any lift that has nothing logged yet, so cards
        // never sit empty. (Lifts with history keep their rolling number.)
        for (liftId, value) in maxes where value > 0 {
            let name = ExerciseCatalog.displayName(for: liftId)
            let stream = LiftStatsService.history(liftId: liftId, liftName: name, entries: oneRepMaxes, sessions: sessions)
            if stream.isEmpty {
                modelContext.insert(OneRepMaxEntry(exerciseId: liftId, exerciseName: name, weight: value, unit: unit, date: Date()))
            }
        }

        // Training a %TM program is template mode; flip coach-mode profiles
        // over so the Plan tab surfaces the new session card.
        profiles.first?.trainingMode = "template"
        try? modelContext.save()

        coordinator.showToast("\(program.name) activated \u{00B7} maxes locked \(blockWeeks) wk", icon: "lock.fill", tone: .success)
        coordinator.selectedTab = .plan
        dismiss()
    }

    /// Snapshots the day with the maxes dialed in above as a plain template:
    /// concrete exercises with sets × reps × weight, editable like any other.
    private func saveDayAsTemplate(_ dayIndex: Int, day: SplitDay, program: ProgramDefinition) {
        let config = ActiveProgram(
            programId: program.id, maxes: maxes, trainingMaxPercent: tmPct,
            includeWarmups: false, currentWeek: 0, unit: unit
        )
        let session = SessionBuilder.buildSession(program: program, config: config, dayIndex: dayIndex)
        guard !session.isEmpty else {
            coordinator.showToast("Set your maxes first", icon: "exclamationmark.triangle")
            return
        }

        let template = WorkoutTemplate(name: "\(program.name) \u{00B7} \(day.name)", kindRaw: TemplateKind.custom.rawValue)
        modelContext.insert(template)
        for (index, exercise) in session.enumerated() {
            let working = exercise.sets.filter { !$0.type.isWarmup }
            let item = TemplateItem(
                orderIndex: index,
                name: exercise.name,
                exerciseId: exercise.exId,
                targetSets: max(1, working.count),
                targetReps: working.first?.reps ?? 5,
                targetWeight: working.map(\.weight).max() ?? 0
            )
            // Keep each set's own weight × reps (preserves ramps like 5/3/1).
            item.setSpecs = working.map { TemplateSetSpec(weight: $0.weight, reps: $0.reps) }
            item.template = template
            modelContext.insert(item)
        }
        try? modelContext.save()

        coordinator.showToast("Saved \(day.name) to Templates", icon: "doc.text", tone: .success)
    }
}
