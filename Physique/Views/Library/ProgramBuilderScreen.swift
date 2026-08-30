import SwiftUI
import SwiftData

/// Author a custom program in %TM, like the books do: days of
/// (lift, sets, reps, %TM) rows plus 2-week waves that raise the percentages.
struct ProgramBuilderScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext

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

    @State private var savedDefinition: ProgramDefinition?
    @State private var showDetail = false

    private static let dayNames = ["Day A", "Day B", "Day C", "Day D", "Day E", "Day F"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Name
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
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                // Day chips
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
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s3)

                // Rows for the selected day
                VStack(spacing: 0) {
                    ForEach(Array(days[dayIndex].rows.enumerated()), id: \.element.id) { rowIndex, row in
                        HStack(spacing: Spacing.s2) {
                            liftMenu(rowIndex: rowIndex, row: row)
                            Spacer(minLength: 0)
                            numberField(value: bindingForRow(rowIndex, \.sets), range: 1...10)
                            numberField(value: bindingForRow(rowIndex, \.reps), range: 1...30)
                            numberField(value: bindingForRow(rowIndex, \.pct), range: 30...100)
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s2)
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

                    // Column labels
                    HStack(spacing: Spacing.s2) {
                        Spacer()
                        ForEach(["SETS", "REPS", "%TM"], id: \.self) { label in
                            Text(label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(theme.text3)
                                .tracking(0.5)
                                .frame(width: 46)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s1)

                    // Add exercise
                    Button {
                        days[dayIndex].rows.append(CustomProgramRow(liftId: "squat", sets: 3, reps: 5, pct: waves.first ?? 70))
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
                .padding(.vertical, Spacing.s2)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(theme.hairline, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s3)

                // Waves
                SectionLabel(text: "Week waves")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                HStack(spacing: Spacing.s2) {
                    ForEach(waves.indices, id: \.self) { index in
                        VStack(spacing: Spacing.s1) {
                            Text("Wk \(index * 2 + 1)\u{2013}\(index * 2 + 2)")
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
                .padding(.horizontal, Spacing.s4)

                // Continue
                Button {
                    saveAndContinue()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.physique(.primary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

                Spacer()
                    .frame(height: Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle("New program")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDetail) {
            if let definition = savedDefinition {
                ProgramDetailScreen(program: definition)
            }
        }
    }

    // MARK: - Row controls

    private func liftMenu(rowIndex: Int, row: CustomProgramRow) -> some View {
        Menu {
            ForEach(BuiltInPrograms.lifts.sorted(by: { $0.value.name < $1.value.name }), id: \.key) { liftId, lift in
                Button(lift.name) {
                    days[dayIndex].rows[rowIndex].liftId = liftId
                }
            }
        } label: {
            HStack(spacing: Spacing.s1) {
                Text(BuiltInPrograms.lifts[row.liftId]?.name ?? row.liftId.capitalized)
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(theme.text3)
            }
        }
    }

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
        // Re-letter so the chips stay Day A, Day B, ...
        for i in days.indices {
            days[i].name = Self.dayNames[i]
        }
        dayIndex = min(dayIndex, days.count - 1)
    }

    // MARK: - Save

    private func saveAndContinue() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let program = CustomProgram(
            name: trimmedName.isEmpty ? "My program" : trimmedName,
            days: days,
            wavePcts: waves
        )
        modelContext.insert(program)
        try? modelContext.save()
        savedDefinition = program.definition(forWeek: 0)
        showDetail = true
    }
}
