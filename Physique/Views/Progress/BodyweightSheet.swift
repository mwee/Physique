import SwiftUI
import SwiftData

struct BodyweightSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var entries: [BodyweightEntry]

    @State private var showAddEntry = false
    @State private var isEditing = false
    @State private var newWeight: String = ""
    @State private var selectedUnit: WeightUnit = .lb

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Chart card
                    chartCard
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s4)

                    // Add measurement button
                    Button {
                        showAddEntry = true
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add measurement")
                        }
                    }
                    .buttonStyle(.physique(.primary))
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
            .navigationTitle("Bodyweight")
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
            .alert("Add Measurement", isPresented: $showAddEntry) {
                TextField("Weight", text: $newWeight)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    newWeight = ""
                }
                Button("Save") {
                    saveEntry()
                }
            } message: {
                Text("Enter your current bodyweight in \(selectedUnit.displayName).")
            }
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            // Current weight display
            HStack(alignment: .lastTextBaseline) {
                if let latest = entries.first {
                    Text(WeightFormatter.format(latest.weight))
                        .font(.system(size: TypeScale.title1, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)
                    Text(latest.unit.displayName)
                        .font(.system(size: TypeScale.sub, weight: .medium))
                        .foregroundStyle(theme.text3)
                } else {
                    Text("\u{2014}")
                        .font(.system(size: TypeScale.title1, weight: .bold))
                        .foregroundStyle(theme.text3)
                }

                Spacer()

                // Delta
                if entries.count >= 2 {
                    let delta = entries[0].weight - entries[1].weight
                    if delta != 0 {
                        HStack(spacing: Spacing.s1) {
                            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(WeightFormatter.format(abs(delta))) \(entries[0].unit.displayName)")
                                .font(.system(size: TypeScale.footnote, weight: .bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(delta > 0 ? Color.dangerRed : Color.successGreen)
                    }
                }
            }

            // Line chart
            if entries.count >= 2 {
                let chartData = Array(entries.prefix(30).reversed().map(\.weight))
                LineChartView(
                    data: chartData,
                    height: 120,
                    showArea: true,
                    showDot: true,
                    strokeColor: .accent
                )
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
                        Text(TimeFormatter.fullDay(entry.date))
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)
                        if let timeString = entry.timeString {
                            Text(timeString)
                                .font(.system(size: TypeScale.sub))
                                .foregroundStyle(theme.text3)
                        } else {
                            Text(formattedTime(entry.date))
                                .font(.system(size: TypeScale.sub))
                                .foregroundStyle(theme.text3)
                        }
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
        guard let weight = Double(newWeight), weight > 0 else {
            newWeight = ""
            return
        }
        let entry = BodyweightEntry(
            weight: weight,
            unit: selectedUnit,
            date: Date(),
            timeString: formattedTime(Date())
        )
        modelContext.insert(entry)
        newWeight = ""
    }
}
