import SwiftUI
import SwiftData

/// One lift's 1RM control center: current max, trend chart, the most recent
/// top sets, and a way to log a freshly tested max.
struct LiftDetailScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let liftId: String
    let liftName: String

    @State private var showWeightEntry = false
    @State private var newWeight = ""

    private var history: [LiftStatsService.DatedMax] {
        LiftStatsService.history(liftId: liftId, liftName: liftName, entries: oneRepMaxes, sessions: sessions)
    }

    var body: some View {
        let history = self.history
        let topSets = LiftStatsService.recentTopSets(liftId: liftId, liftName: liftName, sessions: sessions)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Current max
                HStack(alignment: .lastTextBaseline, spacing: Spacing.s2) {
                    if let current = LiftStatsService.currentMax(in: history) {
                        Text(WeightFormatter.format(current))
                            .font(.system(size: TypeScale.display, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(theme.text)
                        Text("lb")
                            .font(.system(size: TypeScale.body, weight: .bold))
                            .foregroundStyle(theme.text3)
                        if LiftStatsService.isAtPeak(history) {
                            PillView(text: "PR", tone: .pr, icon: "flame.fill")
                                .padding(.leading, Spacing.s1)
                        }
                    } else {
                        Text("\u{2014}")
                            .font(.system(size: TypeScale.display, weight: .bold))
                            .foregroundStyle(theme.text3)
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s2)

                // Trend chart
                if history.count >= 2 {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        LineChartView(data: history.map(\.value), height: 110)
                        HStack {
                            Text(TimeFormatter.relativeDay(history.first?.date ?? Date()))
                            Spacer()
                            Text(TimeFormatter.relativeDay(history.last?.date ?? Date()))
                        }
                        .font(.system(size: TypeScale.caption, weight: .semibold))
                        .foregroundStyle(theme.text3)
                    }
                    .card(padding: Spacing.s4)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)
                } else {
                    Text("Log workouts or a tested max and your \(liftName) trend will chart here.")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text3)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .card(padding: Spacing.s5)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s4)
                }

                // Recent top sets
                if !topSets.isEmpty {
                    SectionLabel(text: "Recent top sets")
                        .padding(.top, Spacing.s6)
                        .padding(.bottom, Spacing.s3)

                    VStack(spacing: 0) {
                        ForEach(Array(topSets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text(set.display)
                                    .font(.system(size: TypeScale.body, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.text)
                                Spacer()
                                Text(set.dateLabel)
                                    .font(.system(size: TypeScale.footnote, weight: .semibold))
                                    .foregroundStyle(theme.text3)
                            }
                            .padding(.horizontal, Spacing.s4)
                            .padding(.vertical, Spacing.s3)

                            if index < topSets.count - 1 {
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

                // Log tested max
                Button {
                    newWeight = ""
                    showWeightEntry = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14))
                        Text("Log a tested 1RM")
                    }
                }
                .buttonStyle(.physique(.secondary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

                Spacer()
                    .frame(height: Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle(liftName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Set 1RM", isPresented: $showWeightEntry) {
            TextField("Weight", text: $newWeight)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { newWeight = "" }
            Button("Save") { saveEntry() }
        } message: {
            Text("Enter your tested 1 rep max for \(liftName) in lb.")
        }
    }

    private func saveEntry() {
        guard let weight = Double(newWeight), weight > 0 else {
            newWeight = ""
            return
        }
        let entry = OneRepMaxEntry(
            exerciseId: liftId,
            exerciseName: liftName,
            weight: weight,
            unit: .lb,
            date: Date()
        )
        modelContext.insert(entry)
        try? modelContext.save()
        newWeight = ""
    }
}
