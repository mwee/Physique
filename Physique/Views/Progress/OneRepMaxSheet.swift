import SwiftUI
import SwiftData

struct OneRepMaxSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var entries: [OneRepMaxEntry]

    @State private var showPicker = false
    @State private var showWeightEntry = false
    @State private var isEditing = false
    @State private var newWeight: String = ""
    @State private var selectedUnit: WeightUnit = .lb
    @State private var pendingLift: TrackedLift?
    @State private var pickedExercise: Exercise?

    // Default lifts always shown so the user has somewhere to start.
    private static let defaultLifts: [TrackedLift] = [
        TrackedLift(id: "deadlift", name: "Deadlift"),
        TrackedLift(id: "bench", name: "Bench Press"),
        TrackedLift(id: "squat", name: "Back Squat"),
        TrackedLift(id: "ohp", name: "Overhead Press"),
    ]

    struct TrackedLift: Identifiable, Equatable {
        let id: String
        let name: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Chart card
                    chartCard
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s4)

                    // Tracked lifts
                    SectionLabel(text: "Lifts")
                        .padding(.top, Spacing.s6)
                        .padding(.bottom, Spacing.s3)

                    liftsList
                        .padding(.horizontal, Spacing.s4)

                    // Add lift button
                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add lift to track")
                        }
                    }
                    .buttonStyle(.physique(.secondary))
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                    // History list
                    if !entries.isEmpty {
                        SectionLabel(text: "History")
                            .padding(.top, Spacing.s6)
                            .padding(.bottom, Spacing.s3)

                        historyList
                            .padding(.horizontal, Spacing.s4)
                    }

                    Spacer()
                        .frame(height: Spacing.s10)
                }
            }
            .background(theme.bg)
            .navigationTitle("1 Rep Max")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.text2)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { isEditing.toggle() }
                    }
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(Color.accent)
                }
            }
            .sheet(isPresented: $showPicker, onDismiss: {
                if let picked = pickedExercise {
                    pendingLift = TrackedLift(id: picked.id, name: picked.name)
                    pickedExercise = nil
                    newWeight = ""
                    showWeightEntry = true
                }
            }) {
                ExercisePickerSheet { exercise in
                    pickedExercise = exercise
                }
                .environment(\.theme, PhysiqueColors.dark)
                .preferredColorScheme(.dark)
            }
            .alert("Set 1RM", isPresented: $showWeightEntry) {
                TextField("Weight", text: $newWeight)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    newWeight = ""
                    pendingLift = nil
                }
                Button("Save") {
                    saveEntry()
                }
            } message: {
                Text("Enter your 1 rep max for \(pendingLift?.name ?? "this exercise") in \(selectedUnit.displayName).")
            }
        }
    }

    // MARK: - Tracked lifts

    /// Default lifts first, then any other lifts the user has logged.
    private var trackedLifts: [TrackedLift] {
        var seen = Set<String>()
        var result: [TrackedLift] = []
        for lift in Self.defaultLifts {
            result.append(lift)
            seen.insert(lift.id)
        }
        for entry in entries where !seen.contains(entry.exerciseId) {
            result.append(TrackedLift(id: entry.exerciseId, name: entry.exerciseName))
            seen.insert(entry.exerciseId)
        }
        return result
    }

    private func latestEntry(for liftId: String) -> OneRepMaxEntry? {
        entries.first { $0.exerciseId == liftId }
    }

    private var liftsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(trackedLifts.enumerated()), id: \.element.id) { index, lift in
                Button {
                    pendingLift = lift
                    newWeight = latestEntry(for: lift.id).map { WeightFormatter.format($0.weight) } ?? ""
                    showWeightEntry = true
                } label: {
                    HStack {
                        Text(lift.name)
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)

                        Spacer()

                        if let latest = latestEntry(for: lift.id) {
                            Text("\(WeightFormatter.format(latest.weight)) \(latest.unit.displayName)")
                                .font(.system(size: TypeScale.body, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.text)
                        } else {
                            Text("Add")
                                .font(.system(size: TypeScale.sub, weight: .semibold))
                                .foregroundStyle(Color.accent)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.text3)
                            .padding(.leading, Spacing.s2)
                    }
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s3)
                }
                .buttonStyle(.plain)

                if index < trackedLifts.count - 1 {
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

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .lastTextBaseline) {
                if let latest = entries.first {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(latest.exerciseName)
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text3)
                        HStack(alignment: .lastTextBaseline, spacing: Spacing.s1) {
                            Text(WeightFormatter.format(latest.weight))
                                .font(.system(size: TypeScale.title1, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.text)
                            Text(latest.unit.displayName)
                                .font(.system(size: TypeScale.sub, weight: .medium))
                                .foregroundStyle(theme.text3)
                        }
                    }
                } else {
                    Text("\u{2014}")
                        .font(.system(size: TypeScale.title1, weight: .bold))
                        .foregroundStyle(theme.text3)
                }

                Spacer()

                // Delta vs previous entry for the same exercise
                if let latest = entries.first,
                   let previous = entries.dropFirst().first(where: { $0.exerciseId == latest.exerciseId }) {
                    let delta = latest.weight - previous.weight
                    if delta != 0 {
                        HStack(spacing: Spacing.s1) {
                            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(WeightFormatter.format(abs(delta))) \(latest.unit.displayName)")
                                .font(.system(size: TypeScale.footnote, weight: .bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(delta > 0 ? Color.successGreen : Color.dangerRed)
                    }
                }
            }

            // Line chart of the latest exercise's history (chronological)
            if let latest = entries.first {
                let history = entries
                    .filter { $0.exerciseId == latest.exerciseId }
                    .prefix(30)
                    .reversed()
                    .map(\.weight)
                if history.count >= 2 {
                    LineChartView(
                        data: Array(history),
                        height: 120,
                        showArea: true,
                        showDot: true,
                        strokeColor: .accent
                    )
                }
            }
        }
        .card()
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.exerciseName)
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)
                        Text(TimeFormatter.fullDay(entry.date))
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text3)
                    }

                    Spacer()

                    Text("\(WeightFormatter.format(entry.weight)) \(entry.unit.displayName)")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)

                    if isEditing {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(entry)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dangerRed)
                        }
                        .padding(.leading, Spacing.s3)
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)

                if index < entries.count - 1 {
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

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func saveEntry() {
        guard let lift = pendingLift,
              let weight = Double(newWeight), weight > 0 else {
            newWeight = ""
            pendingLift = nil
            return
        }
        let entry = OneRepMaxEntry(
            exerciseId: lift.id,
            exerciseName: lift.name,
            weight: weight,
            unit: selectedUnit,
            date: Date(),
            timeString: formattedTime(Date())
        )
        modelContext.insert(entry)
        newWeight = ""
        pendingLift = nil
    }
}
