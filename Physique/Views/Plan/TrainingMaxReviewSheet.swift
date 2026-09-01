import SwiftUI
import SwiftData

/// End-of-block review: shows each lift's locked max next to the max the
/// user's workouts now suggest, lets them adjust, and starts the next block.
struct TrainingMaxReviewSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    let active: ActiveProgram
    let definition: ProgramDefinition

    @State private var newMaxes: [String: Double] = [:]

    private var isComplete: Bool { TrainingBlockService.isBlockComplete(active) }
    private var unit: WeightUnit { active.unit }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerCard
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s4)

                    SectionLabel(text: "Your maxes")
                        .padding(.top, Spacing.s6)
                        .padding(.bottom, Spacing.s3)

                    VStack(spacing: Spacing.s3) {
                        ForEach(definition.liftIds, id: \.self) { liftId in
                            liftCard(liftId)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)

                    Spacer().frame(height: Spacing.s10)
                }
            }
            .background(theme.bg)
            .navigationTitle(isComplete ? "Block complete" : "Training maxes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(theme.text2)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Spacing.s2) {
                    Button {
                        apply(newMaxes)
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "lock.open.fill").font(.system(size: 14))
                            Text("Start next block with these maxes")
                        }
                    }
                    .buttonStyle(.physique(.primary))

                    Button("Keep current maxes") {
                        apply(active.maxes)
                    }
                    .buttonStyle(.physique(.ghost))
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s4)
                .background(.ultraThinMaterial)
            }
            .onAppear(perform: seedSuggestions)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                Image(systemName: isComplete ? "flag.checkered" : "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.prGold)
                Text(isComplete
                     ? "Block \(active.blocksCompleted + 1) done \u{00B7} \(active.blockWeeks) weeks"
                     : "\(TrainingBlockService.blockLabel(active)) \u{00B7} maxes locked")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
            }
            Text(isComplete
                 ? "Your training maxes stayed locked for the whole block. Here\u{2019}s what your workouts say they should be now \u{2014} adjust anything, then start the next block."
                 : "Maxes are normally reviewed at the end of the block. You can update them early here; the current block restarts with the new numbers.")
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Spacing.s4)
    }

    // MARK: - Lift card

    private func liftCard(_ liftId: String) -> some View {
        let name = ExerciseCatalog.displayName(for: liftId)
        let locked = TrainingBlockService.lockedMax(liftId: liftId, active: active) ?? 0
        let calculated = calculatedMax(liftId, name: name)
        let proposed = newMaxes[liftId] ?? locked
        let delta = proposed - locked

        return VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                Text(name)
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
                Spacer()
                if delta != 0 {
                    PillView(
                        text: "\(delta > 0 ? "+" : "\u{2212}")\(WeightFormatter.format(abs(delta)))",
                        tone: delta > 0 ? .success : .neutral,
                        icon: delta > 0 ? "arrow.up" : "arrow.down"
                    )
                }
            }

            HStack(spacing: Spacing.s3) {
                stat("Locked 1RM", value: locked, icon: "lock.fill")
                stat("From workouts", value: calculated, icon: "chart.line.uptrend.xyaxis",
                     highlight: (calculated ?? 0) > locked)
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("New 1RM")
                        .font(.system(size: TypeScale.caption, weight: .bold))
                        .foregroundStyle(theme.text3)
                        .tracking(0.5)
                    if definition.basis == .trainingMax {
                        let tm = ProgramEngine.basisWeight(oneRM: proposed, program: definition, tmPct: active.trainingMaxPercent, unit: unit)
                        Text("TM \(WeightFormatter.format(tm)) at \(active.trainingMaxPercent)%")
                            .font(.system(size: TypeScale.footnote))
                            .monospacedDigit()
                            .foregroundStyle(theme.text2)
                    }
                }
                Spacer()
                stepper(liftId: liftId, value: proposed)
            }
        }
        .card(padding: Spacing.s4)
    }

    private func stat(_ label: String, value: Double?, icon: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(label.uppercased()).tracking(0.5)
            }
            .font(.system(size: TypeScale.caption, weight: .semibold))
            .foregroundStyle(theme.text3)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value.map { WeightFormatter.format($0) } ?? "\u{2014}")
                    .font(.system(size: TypeScale.title3, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(highlight ? Color.successGreen : theme.text)
                Text(unit.displayName)
                    .font(.system(size: TypeScale.caption, weight: .bold))
                    .foregroundStyle(theme.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s3)
        .background(theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }

    private func stepper(liftId: String, value: Double) -> some View {
        HStack(spacing: Spacing.s2) {
            Button {
                newMaxes[liftId] = max(0, value - unit.increment)
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
                    get: { newMaxes[liftId] ?? value },
                    set: { newMaxes[liftId] = max(0, $0) }
                ), width: 64)
                Text(unit.displayName)
                    .font(.system(size: TypeScale.caption, weight: .bold))
                    .foregroundStyle(theme.text3)
            }
            Button {
                newMaxes[liftId] = value + unit.increment
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

    // MARK: - Data

    private func calculatedMax(_ liftId: String, name: String) -> Double? {
        let history = LiftStatsService.history(liftId: liftId, liftName: name, entries: oneRepMaxes, sessions: sessions)
        return LiftStatsService.currentMax(in: history)
    }

    private func seedSuggestions() {
        guard newMaxes.isEmpty else { return }
        for liftId in definition.liftIds {
            let locked = TrainingBlockService.lockedMax(liftId: liftId, active: active) ?? 0
            let calculated = calculatedMax(liftId, name: ExerciseCatalog.displayName(for: liftId))
            newMaxes[liftId] = TrainingBlockService.suggestedMax(liftId: liftId, locked: locked, calculated: calculated, unit: unit)
        }
    }

    private func apply(_ maxes: [String: Double]) {
        TrainingBlockService.startNextBlock(active, maxes: maxes, definition: definition)
        try? modelContext.save()
        coordinator.showToast("Block \(active.blocksCompleted + 1) started", icon: "lock.fill", tone: .success)
        dismiss()
    }
}
