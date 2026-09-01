import SwiftUI
import SwiftData

/// Author (or edit) a custom program in %TM, the way the books do: days of
/// (lift, sets, reps, %TM) rows plus three waves that raise the percentages
/// across a 3- or 6-week block. Working weights preview live from the
/// user's current 1RMs so the program reads in real numbers as it's built.
struct ProgramBuilderScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]
    @Query private var exerciseCatalog: [Exercise]
    @Query private var activePrograms: [ActiveProgram]

    /// When set, edits this program in place instead of creating a new one.
    var existing: CustomProgram? = nil

    @State private var name = "My program"
    @State private var dayIndex = 0
    @State private var days: [CustomProgramDay] = [
        CustomProgramDay(name: "Day A", rows: [
            CustomProgramRow(liftId: "squat", sets: 3, reps: 5, pct: 70),
            CustomProgramRow(liftId: "bench", sets: 3, reps: 5, pct: 70),
        ]),
        CustomProgramDay(name: "Day B", rows: [
            CustomProgramRow(liftId: "squat", sets: 3, reps: 5, pct: 70),
            CustomProgramRow(liftId: "ohp", sets: 3, reps: 5, pct: 70),
        ]),
        CustomProgramDay(name: "Day C", rows: [
            CustomProgramRow(liftId: "deadlift", sets: 3, reps: 5, pct: 70),
            CustomProgramRow(liftId: "bench", sets: 3, reps: 5, pct: 70),
        ]),
    ]
    @State private var waves: [Int] = [70, 80, 90]
    @State private var waveWeeks = 2
    @State private var loaded = false

    // Exercise picker
    @State private var showPicker = false
    @State private var pickerReplacesRow: Int?

    // Inline "set a 1RM" entry
    @State private var maxEntryLift: String?
    @State private var maxEntryText = ""

    @State private var savedDefinition: ProgramDefinition?
    @State private var showDetail = false

    private static let dayNames = ["Day A", "Day B", "Day C", "Day D", "Day E", "Day F"]

    private var isEditing: Bool { existing != nil }
    private var unit: WeightUnit { profiles.first?.weightUnit ?? .lb }
    private var tmPct: Int { profiles.first?.defaultTrainingMaxPercent ?? 90 }
    private var blockWeeks: Int { waves.count * waveWeeks }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                nameField
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                sourceNote
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)

                dayChips
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                dayCard
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)

                SectionLabel(text: "Training block")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                blockPicker
                    .padding(.horizontal, Spacing.s4)

                SectionLabel(text: "Waves \u{00B7} %TM")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                wavesRow
                    .padding(.horizontal, Spacing.s4)

                Button {
                    save()
                } label: {
                    Text(isEditing ? "Save changes" : "Continue")
                }
                .buttonStyle(.physique(.primary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

                Spacer().frame(height: Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle(isEditing ? "Edit program" : "New program")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDetail) {
            if let definition = savedDefinition {
                ProgramDetailScreen(program: definition)
            }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { exercise in
                if let rowIndex = pickerReplacesRow, days[dayIndex].rows.indices.contains(rowIndex) {
                    days[dayIndex].rows[rowIndex].liftId = exercise.id
                } else {
                    days[dayIndex].rows.append(
                        CustomProgramRow(liftId: exercise.id, sets: 3, reps: 5, pct: waves.first ?? 70)
                    )
                }
                pickerReplacesRow = nil
            }
            .environment(\.theme, PhysiqueColors.dark)
            .preferredColorScheme(.dark)
        }
        .alert("Set 1RM", isPresented: Binding(
            get: { maxEntryLift != nil },
            set: { if !$0 { maxEntryLift = nil } }
        )) {
            TextField("Weight", text: $maxEntryText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { maxEntryLift = nil }
            Button("Save") { saveMaxEntry() }
        } message: {
            Text("Enter your 1 rep max for \(maxEntryLift.map(liftName) ?? "this lift") in \(unit.displayName). The builder will use it right away.")
        }
        .onAppear(perform: loadExisting)
    }

    // MARK: - Pieces

    private var nameField: some View {
        TextField("Program name", text: $name)
            .font(.system(size: TypeScale.body, weight: .bold))
            .foregroundStyle(theme.text)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s3)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .stroke(theme.hairline, lineWidth: 1)
            )
    }

    private var sourceNote: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.accent)
            Text("Weights preview from your current 1RM \u{00D7} \(tmPct)% training max. Maxes lock when you activate.")
                .font(.system(size: TypeScale.footnote))
                .foregroundStyle(theme.text3)
        }
    }

    private var dayChips: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                Button(day.name) {
                    dayIndex = index
                }
                .font(.system(size: TypeScale.sub, weight: .semibold))
                .foregroundStyle(index == dayIndex ? .onAccent : theme.text2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s2)
                .background(index == dayIndex ? Color.accent : theme.surface2)
                .clipShape(Capsule())
                .contextMenu {
                    if days.count > 1 {
                        Button(role: .destructive) {
                            removeDay(at: index)
                        } label: {
                            Label("Remove \(day.name)", systemImage: "trash")
                        }
                    }
                }
            }

            if days.count < Self.dayNames.count {
                Button {
                    addDay()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accent)
                        .frame(width: 34, height: 30)
                        .background(Color.accent.opacity(0.22))
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Add day")
            }
        }
    }

    private var dayCard: some View {
        VStack(spacing: 0) {
            // Column labels
            HStack(spacing: Spacing.s2) {
                Text("EXERCISE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(["SETS", "REPS", "%TM"], id: \.self) { label in
                    Text(label).frame(width: 46)
                }
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(theme.text3)
            .tracking(0.5)
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s3)
            .padding(.bottom, Spacing.s1)

            ForEach(Array(days[dayIndex].rows.enumerated()), id: \.element.id) { rowIndex, row in
                exerciseRow(rowIndex: rowIndex, row: row)
                    .contextMenu {
                        if days[dayIndex].rows.count > 1 {
                            Button(role: .destructive) {
                                days[dayIndex].rows.remove(at: rowIndex)
                            } label: {
                                Label("Remove exercise", systemImage: "trash")
                            }
                        }
                    }

                Divider()
                    .background(theme.hairline)
                    .padding(.leading, Spacing.s4)
            }

            Button {
                pickerReplacesRow = nil
                showPicker = true
            } label: {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add exercise")
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                }
                .foregroundStyle(Color.accent)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    /// One prescription row plus a live "1RM → TM → working weight" line.
    private func exerciseRow(rowIndex: Int, row: CustomProgramRow) -> some View {
        let oneRM = currentMax(row.liftId)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Spacing.s2) {
                Button {
                    pickerReplacesRow = rowIndex
                    showPicker = true
                } label: {
                    HStack(spacing: Spacing.s1) {
                        Text(liftName(row.liftId))
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                numberField(value: bindingForRow(rowIndex, \.sets), range: 1...10)
                numberField(value: bindingForRow(rowIndex, \.reps), range: 1...30)
                numberField(value: bindingForRow(rowIndex, \.pct), range: 30...100)
            }

            HStack(spacing: Spacing.s1) {
                if let oneRM {
                    let tm = WeightFormatter.roundToPlate(oneRM * Double(tmPct) / 100, unit: unit)
                    let working = WeightFormatter.roundToPlate(tm * Double(row.pct) / 100, unit: unit)
                    Text("1RM \(WeightFormatter.format(oneRM)) \u{2192} TM \(WeightFormatter.format(tm)) \u{2192}")
                        .foregroundStyle(theme.text3)
                    Text("\(WeightFormatter.format(working)) \(unit.displayName)")
                        .foregroundStyle(theme.text2)
                        .fontWeight(.bold)
                } else {
                    Text("No 1RM yet")
                        .foregroundStyle(theme.text3)
                    Button("Set 1RM") {
                        maxEntryText = ""
                        maxEntryLift = row.liftId
                    }
                    .foregroundStyle(Color.accent)
                    .fontWeight(.bold)
                    .buttonStyle(.plain)
                }
            }
            .font(.system(size: TypeScale.caption, weight: .semibold))
            .monospacedDigit()
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
    }

    private var blockPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                ForEach([1, 2], id: \.self) { span in
                    let weeks = waves.count * span
                    Button {
                        waveWeeks = span
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(weeks) weeks")
                                .font(.system(size: TypeScale.sub, weight: .bold))
                            Text(span == 1 ? "1-week waves" : "2-week waves")
                                .font(.system(size: TypeScale.caption, weight: .semibold))
                                .opacity(0.8)
                        }
                        .foregroundStyle(waveWeeks == span ? .onAccent : theme.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s2)
                        .background(waveWeeks == span ? Color.accent : theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: Spacing.s1) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("Training maxes stay locked for the \(blockWeeks)-week block, then you review and raise them.")
            }
            .font(.system(size: TypeScale.footnote))
            .foregroundStyle(theme.text3)
        }
    }

    private var wavesRow: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(waves.indices, id: \.self) { index in
                VStack(spacing: Spacing.s1) {
                    Text(waveLabel(index))
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                    numberField(value: Binding(
                        get: { waves[index] },
                        set: { waves[index] = min(100, max(30, $0)) }
                    ), range: 30...100)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s2)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(theme.hairline, lineWidth: 1)
                )
            }
        }
    }

    private func waveLabel(_ index: Int) -> String {
        let start = index * waveWeeks + 1
        return waveWeeks == 1 ? "Wk \(start)" : "Wk \(start)\u{2013}\(start + waveWeeks - 1)"
    }

    // MARK: - Row controls

    private func bindingForRow(_ rowIndex: Int, _ keyPath: WritableKeyPath<CustomProgramRow, Int>) -> Binding<Int> {
        Binding(
            get: { days[dayIndex].rows[rowIndex][keyPath: keyPath] },
            set: { days[dayIndex].rows[rowIndex][keyPath: keyPath] = $0 }
        )
    }

    private func numberField(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        TextField("", value: Binding(
            get: { value.wrappedValue },
            set: { value.wrappedValue = min(range.upperBound, max(range.lowerBound, $0)) }
        ), format: .number)
        .keyboardType(.numberPad)
        .font(.system(size: TypeScale.sub, weight: .bold))
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.text)
        .frame(width: 46)
        .padding(.vertical, 6)
        .background(theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    // MARK: - 1RM lookups

    private func liftName(_ liftId: String) -> String {
        exerciseCatalog.first { $0.id == liftId }?.name ?? ExerciseCatalog.displayName(for: liftId)
    }

    private func currentMax(_ liftId: String) -> Double? {
        let history = LiftStatsService.history(
            liftId: liftId, liftName: liftName(liftId), entries: oneRepMaxes, sessions: sessions
        )
        return LiftStatsService.currentMax(in: history)
    }

    private func saveMaxEntry() {
        guard let liftId = maxEntryLift, let weight = Double(maxEntryText), weight > 0 else {
            maxEntryLift = nil
            return
        }
        modelContext.insert(OneRepMaxEntry(
            exerciseId: liftId, exerciseName: liftName(liftId), weight: weight, unit: unit, date: Date()
        ))
        try? modelContext.save()
        maxEntryLift = nil
    }

    // MARK: - Day management

    private func addDay() {
        let nextName = Self.dayNames[days.count]
        days.append(CustomProgramDay(name: nextName, rows: [
            CustomProgramRow(liftId: "squat", sets: 3, reps: 5, pct: waves.first ?? 70),
        ]))
        dayIndex = days.count - 1
    }

    private func removeDay(at index: Int) {
        days.remove(at: index)
        for i in days.indices {
            days[i].name = Self.dayNames[i]
        }
        dayIndex = min(dayIndex, days.count - 1)
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard !loaded, let existing else { return }
        loaded = true
        name = existing.name
        let existingDays = existing.days
        if !existingDays.isEmpty { days = existingDays }
        if !existing.wavePcts.isEmpty { waves = existing.wavePcts }
        waveWeeks = max(1, min(2, existing.waveWeeks))
        dayIndex = 0
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? "My program" : trimmedName

        if let existing {
            existing.name = finalName
            existing.days = days
            existing.wavePcts = waves
            existing.waveWeeks = waveWeeks
            // If this program is running, make sure every lift it now needs
            // has a max so sessions keep building.
            if let active = activePrograms.first, active.programId == existing.programId {
                let definition = existing.definition(forWeek: active.currentWeek)
                TrainingBlockService.fillMissingMaxes(active, definition: definition, entries: oneRepMaxes, sessions: sessions)
            }
            try? modelContext.save()
            coordinator.showToast("Program updated", icon: "checkmark", tone: .success)
            dismiss()
        } else {
            let program = CustomProgram(name: finalName, days: days, wavePcts: waves, waveWeeks: waveWeeks)
            modelContext.insert(program)
            try? modelContext.save()
            savedDefinition = program.definition(forWeek: 0)
            showDetail = true
        }
    }
}
