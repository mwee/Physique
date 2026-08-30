import SwiftUI
import SwiftData

struct ProgramDetailScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query private var profiles: [UserProfile]
    let program: ProgramDefinition
    @State private var maxes: [String: Double] = [:]
    @State private var tmPct: Int = 90
    @State private var includeWarmups: Bool = false
    @State private var unit: WeightUnit = .lb
    @State private var expandedDay: Int?

    var body: some View {
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

                // Tags + meta
                HStack(spacing: Spacing.s2) {
                    ForEach(program.tags, id: \.self) { tag in
                        PillView(text: tag, tone: .accent)
                    }
                    PillView(text: program.days, tone: .neutral)
                    PillView(text: program.cycle, tone: .neutral)
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

                // 1RM Steppers
                SectionLabel(text: "Your maxes")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: Spacing.s3) {
                    ForEach(program.liftIds, id: \.self) { liftId in
                        let liftName = BuiltInPrograms.lifts[liftId]?.name ?? liftId
                        HStack {
                            Text(liftName)
                                .font(.system(size: TypeScale.body, weight: .semibold))
                                .foregroundStyle(theme.text)

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

                                Text("\(WeightFormatter.format(maxes[liftId, default: defaultMax(liftId)])) \(unit.rawValue)")
                                    .font(.system(size: TypeScale.body, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.text)
                                    .frame(width: 80, alignment: .center)

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
                }

                // Options row (TM% for programs that use it)
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

                // Week 1 preview with the user's maxes
                SectionLabel(text: "Week 1 \u{00B7} with your maxes")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                weekOnePreview
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
                    activateProgram()
                } label: {
                    Text("Use this program")
                }
                .buttonStyle(.physique(.primary))

                if !program.id.hasPrefix("custom-") {
                    Button {
                        saveAsTemplate()
                    } label: {
                        Text("Save to My Templates")
                    }
                    .buttonStyle(.physique(.secondary))
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s4)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Seed default maxes
            for liftId in program.liftIds {
                if maxes[liftId] == nil {
                    maxes[liftId] = defaultMax(liftId)
                }
            }
        }
    }

    // MARK: - Week 1 Preview

    /// Expandable per-day preview of the first week, computed from the maxes
    /// and TM% currently dialed in above.
    private var weekOnePreview: some View {
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
                                if !isOpen, let summary = daySummary(day) {
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
    private func daySummary(_ day: SplitDay) -> String? {
        var liftIds: [String] = []
        if let items = day.items {
            liftIds = items.map(\.id)
        } else if !day.ids.isEmpty {
            liftIds = day.ids
        } else if program.single {
            liftIds = program.liftIds
        }
        guard !liftIds.isEmpty else { return day.sub }
        let names = liftIds.map { BuiltInPrograms.lifts[$0]?.short ?? $0.capitalized }
        return names.joined(separator: " \u{00B7} ")
    }

    private func defaultMax(_ liftId: String) -> Double {
        // Prefer the user's most recent manually-entered 1RM for this lift
        // (exerciseId == liftId). Fall back to the program's built-in default.
        if let logged = oneRepMaxes.first(where: { $0.exerciseId == liftId && $0.unit == unit }) {
            return WeightFormatter.roundToPlate(logged.weight, unit: unit)
        }
        return BuiltInPrograms.defaults[unit]?[liftId] ?? 135
    }

    private func activateProgram() {
        // Remove existing active program
        let descriptor = FetchDescriptor<ActiveProgram>()
        if let existing = try? modelContext.fetch(descriptor) {
            for p in existing { modelContext.delete(p) }
        }

        let active = ActiveProgram(
            programId: program.id,
            maxes: maxes,
            trainingMaxPercent: tmPct,
            includeWarmups: includeWarmups,
            unit: unit
        )
        modelContext.insert(active)
        // Training a %TM program is template mode; flip coach-mode profiles
        // over so the Plan tab surfaces the new session card.
        profiles.first?.trainingMode = "template"
        try? modelContext.save()

        coordinator.showToast("\(program.name) activated", icon: "checkmark", tone: .success)
        coordinator.selectedTab = .plan
        dismiss()
    }

    private func saveAsTemplate() {
        let template = WorkoutTemplate(
            name: program.name,
            kindRaw: TemplateKind.program.rawValue,
            programId: program.id,
            maxes: maxes,
            trainingMaxPercent: tmPct,
            includeWarmups: includeWarmups,
            unit: unit,
            dayIndex: 0
        )
        modelContext.insert(template)
        try? modelContext.save()

        coordinator.showToast("Saved to My Templates", icon: "checkmark", tone: .success)
    }
}
