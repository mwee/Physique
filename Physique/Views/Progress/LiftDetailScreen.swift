import SwiftUI
import SwiftData
import Charts

/// One lift, one number: the rolling-best e1RM, charted over time with the
/// program's training max as a dotted staircase underneath (plan users only),
/// a session log, and the primary action of logging a tested max.
struct LiftDetailScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var activePrograms: [ActiveProgram]
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]

    let liftId: String
    let liftName: String

    @State private var range: ChartRange = .threeMonths
    @State private var showWeightEntry = false
    @State private var newWeight = ""
    @State private var showBlockReview = false

    enum ChartRange: String, CaseIterable {
        case threeMonths = "3m", sixMonths = "6m", all = "All"

        var startDate: Date? {
            switch self {
            case .threeMonths: Calendar.current.date(byAdding: .day, value: -90, to: Date())
            case .sixMonths: Calendar.current.date(byAdding: .day, value: -180, to: Date())
            case .all: nil
            }
        }
    }

    private var snapshot: LiftStatsService.Snapshot {
        LiftStatsService.snapshot(liftId: liftId, liftName: liftName, entries: oneRepMaxes, sessions: sessions)
    }

    private var activeProgram: ActiveProgram? { activePrograms.first }

    private var activeDefinition: ProgramDefinition? {
        activeProgram.flatMap { ProgramResolver.definition(for: $0, customPrograms: customPrograms) }
    }

    /// TM steps (date, value) for the chart, clipped to the range and carried to today.
    private var trainingMaxSteps: [(date: Date, value: Double)] {
        guard let program = activeProgram, let definition = activeDefinition else { return [] }
        var steps = TrainingBlockService.trainingMaxSteps(liftId: liftId, active: program, definition: definition)
        guard let first = steps.first else { return [] }
        // Anchor the staircase at the left edge of the visible window (the
        // earliest TM in force carries back) so it always reads as a line.
        let leftEdge = range.startDate
            ?? snapshot.points.first.map { min($0.date, first.date) }
            ?? first.date
        let before = steps.filter { $0.date <= leftEdge }
        let after = steps.filter { $0.date > leftEdge }
        steps = [(leftEdge, (before.last ?? first).value)] + after
        if let last = steps.last { steps.append((Date(), last.value)) }
        return steps
    }

    private var currentTrainingMax: Double? {
        TrainingBlockService.lockedTrainingMax(liftId: liftId, active: activeProgram, definition: activeDefinition)
    }

    var body: some View {
        let snapshot = self.snapshot
        let log = LiftStatsService.sessionLog(liftId: liftId, liftName: liftName, sessions: sessions)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero(snapshot)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s2)

                rangeToggle
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                chartCard(snapshot)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)

                planBlock(snapshot)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)

                if !log.isEmpty {
                    SectionLabel(text: "Sessions")
                        .padding(.top, Spacing.s6)
                        .padding(.bottom, Spacing.s3)
                    sessionLog(log)
                        .padding(.horizontal, Spacing.s4)
                }

                Button {
                    newWeight = ""
                    showWeightEntry = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14))
                        Text("Log tested max")
                    }
                }
                .buttonStyle(.physique(.primary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

                Spacer().frame(height: Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle(liftName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Log tested max", isPresented: $showWeightEntry) {
            TextField("Weight", text: $newWeight)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { newWeight = "" }
            Button("Save") { saveEntry() }
        } message: {
            Text("Your best single for \(liftName) in lb. It becomes a tested point in your e1RM history.")
        }
        .sheet(isPresented: $showBlockReview) {
            if let program = activeProgram, let definition = activeDefinition {
                TrainingMaxReviewSheet(active: program, definition: definition)
                    .environment(coordinator)
                    .environment(\.theme, PhysiqueColors.dark)
                    .preferredColorScheme(.dark)
            }
        }
    }

    // MARK: - Hero

    private func hero(_ snapshot: LiftStatsService.Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("E1RM \u{00B7} ROLLING \(LiftStatsService.e1rmWindowDays)-DAY BEST")
                .font(.system(size: TypeScale.caption, weight: .semibold))
                .foregroundStyle(theme.text3)
                .tracking(0.5)

            HStack(alignment: .lastTextBaseline, spacing: Spacing.s2) {
                if let value = snapshot.value ?? activeProgram?.maxes[liftId] {
                    Text(WeightFormatter.format(value))
                        .font(.system(size: TypeScale.display, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(snapshot.isStale ? theme.text3 : theme.text)
                    Text("lb")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .foregroundStyle(theme.text3)
                    if let delta = snapshot.delta30 {
                        PillView(
                            text: "\(delta > 0 ? "+" : "\u{2212}")\(WeightFormatter.format(abs(delta))) \u{00B7} 30d",
                            tone: delta > 0 ? .success : .neutral
                        )
                        .padding(.leading, Spacing.s1)
                    }
                    if snapshot.isAtPeak && !snapshot.isStale && !snapshot.points.isEmpty {
                        PillView(text: "PR", tone: .pr, icon: "flame.fill")
                    }
                } else {
                    Text("Log your first set or tested max")
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text3)
                }
            }

            if snapshot.isStale, let last = snapshot.points.last {
                Text("Stale \u{00B7} last logged \(TimeFormatter.relativeDay(last.date))")
                    .font(.system(size: TypeScale.footnote, weight: .semibold))
                    .foregroundStyle(theme.text3)
            }
        }
    }

    // MARK: - Chart

    private var rangeToggle: some View {
        HStack(spacing: Spacing.s1) {
            ForEach(ChartRange.allCases, id: \.self) { option in
                Button(option.rawValue) { range = option }
                    .font(.system(size: TypeScale.footnote, weight: .bold))
                    .foregroundStyle(range == option ? theme.text : theme.text3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s2)
                    .background(range == option ? theme.surface2 : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                    .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(theme.hairline, lineWidth: 1))
    }

    private func chartCard(_ snapshot: LiftStatsService.Snapshot) -> some View {
        let start = range.startDate
        let points = snapshot.points.filter { point in start.map { point.date >= $0 } ?? true }
        let rolling = snapshot.rolling.filter { point in start.map { point.date >= $0 } ?? true }
        let steps = trainingMaxSteps

        return VStack(alignment: .leading, spacing: Spacing.s3) {
            if rolling.count >= 2 || (!points.isEmpty && !steps.isEmpty) {
                Chart {
                    ForEach(Array(rolling.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("e1RM", point.value),
                            series: .value("Series", "e1RM")
                        )
                        .foregroundStyle(Color.accent)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                        LineMark(
                            x: .value("Date", step.date),
                            y: .value("TM", step.value),
                            series: .value("Series", "TM")
                        )
                        .foregroundStyle(theme.text3)
                        .interpolationMethod(.stepEnd)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 5]))
                    }

                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("e1RM", point.value)
                        )
                        .symbol {
                            if point.tested {
                                Circle()
                                    .fill(Color.accent)
                                    .frame(width: 9, height: 9)
                            } else {
                                Circle()
                                    .strokeBorder(Color.accent, lineWidth: 2)
                                    .background(Circle().fill(theme.surface))
                                    .frame(width: 9, height: 9)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(theme.hairline)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(theme.text3)
                            .font(.system(size: TypeScale.caption, weight: .semibold))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(theme.hairline)
                        AxisValueLabel()
                            .foregroundStyle(theme.text3)
                            .font(.system(size: TypeScale.caption, weight: .semibold))
                    }
                }
                .frame(height: 200)
            } else {
                Text(snapshot.points.isEmpty
                     ? "Log sets or a tested max and your \(liftName) e1RM will chart here."
                     : "Not enough points in this range \u{2014} try a longer one.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text3)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Spacing.s4) {
                legend(label: "Tested") {
                    Circle().fill(Color.accent).frame(width: 8, height: 8)
                }
                legend(label: "Estimated") {
                    Circle().strokeBorder(Color.accent, lineWidth: 2).frame(width: 8, height: 8)
                }
                if !steps.isEmpty {
                    legend(label: "Training max") {
                        Rectangle().fill(theme.text3).frame(width: 14, height: 1.5)
                            .mask(HStack(spacing: 3) { ForEach(0..<3, id: \.self) { _ in Rectangle().frame(width: 3) } })
                    }
                }
                Spacer()
            }
        }
        .card(padding: Spacing.s4)
    }

    private func legend<Swatch: View>(label: String, @ViewBuilder swatch: () -> Swatch) -> some View {
        HStack(spacing: 5) {
            swatch()
            Text(label)
                .font(.system(size: TypeScale.caption, weight: .semibold))
                .foregroundStyle(theme.text3)
        }
    }

    // MARK: - Plan block (plan users only)

    @ViewBuilder
    private func planBlock(_ snapshot: LiftStatsService.Snapshot) -> some View {
        if let program = activeProgram, let definition = activeDefinition, let tm = currentTrainingMax {
            let pct = definition.basis == .trainingMax ? program.trainingMaxPercent : 100
            let needsReset = TrainingBlockService.needsReset(trainingMax: tm, rollingMax: snapshot.value)

            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.accent)
                    Text(definition.name.uppercased())
                        .font(.system(size: TypeScale.caption, weight: .semibold))
                        .foregroundStyle(theme.text3)
                        .tracking(0.5)
                    Spacer()
                    Text(TrainingBlockService.blockLabel(program))
                        .font(.system(size: TypeScale.footnote, weight: .semibold))
                        .foregroundStyle(theme.text3)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("TM \(WeightFormatter.format(tm)) \u{00B7} \(pct)% of max")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)
                    Spacer()
                    Text("Next bump \u{00B7} \(TrainingBlockService.nextBumpDate(program).formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.system(size: TypeScale.footnote, weight: .semibold))
                        .foregroundStyle(theme.text2)
                }

                if needsReset {
                    HStack(alignment: .top, spacing: Spacing.s2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Your TM is above 95% of your e1RM \u{2014} reset it lower so the prescribed work stays repeatable.")
                            .font(.system(size: TypeScale.footnote, weight: .semibold))
                    }
                    .foregroundStyle(Color.prGold)
                }

                Button {
                    showBlockReview = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: needsReset ? "arrow.counterclockwise" : "lock.open")
                            .font(.system(size: 12, weight: .bold))
                        Text(needsReset ? "Reset training max" : "Update training maxes")
                    }
                    .font(.system(size: TypeScale.sub, weight: .bold))
                    .foregroundStyle(needsReset ? Color.prGold : Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s2 + 2)
                    .background(needsReset ? Color.prSoft : theme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Update training maxes")
            }
            .card(padding: Spacing.s4)
        }
    }

    // MARK: - Session log

    private func sessionLog(_ log: [LiftStatsService.SessionLogEntry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(log.enumerated()), id: \.element.id) { index, entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TimeFormatter.relativeDay(entry.date))
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text)
                        Text("Top set \(entry.topSet)")
                            .font(.system(size: TypeScale.footnote))
                            .monospacedDigit()
                            .foregroundStyle(theme.text3)
                    }
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(entry.e1rm > 0 ? WeightFormatter.format(entry.e1rm) : "\u{2014}")
                            .font(.system(size: TypeScale.body, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(entry.e1rm > 0 ? theme.text : theme.text3)
                        Text("e1RM")
                            .font(.system(size: TypeScale.caption, weight: .bold))
                            .foregroundStyle(theme.text3)
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)

                if index < log.count - 1 {
                    Divider().background(theme.hairline).padding(.leading, Spacing.s4)
                }
            }
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(theme.hairline, lineWidth: 1))
    }

    private func saveEntry() {
        guard let weight = Double(newWeight), weight > 0 else {
            newWeight = ""
            return
        }
        modelContext.insert(OneRepMaxEntry(exerciseId: liftId, exerciseName: liftName, weight: weight, unit: .lb, date: Date()))
        try? modelContext.save()
        newWeight = ""
    }
}
