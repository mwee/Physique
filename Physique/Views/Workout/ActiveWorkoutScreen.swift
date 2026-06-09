import SwiftUI
import SwiftData

struct ActiveWorkoutScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var appCoordinator
    @State private var wk = ActiveWorkoutCoordinator()
    @State private var showCancelConfirm = false
    @State private var showExercisePicker = false

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky header
                workoutHeader

                // Scroll body
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title + elapsed
                        VStack(alignment: .leading, spacing: 0) {
                            Text(wk.workoutName)
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(theme.text)

                            if wk.isCoached {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11))
                                    Text("Coached by Physique")
                                        .font(.system(size: TypeScale.footnote, weight: .bold))
                                }
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 5)
                                .background(Color.accent.opacity(0.22))
                                .clipShape(Capsule())
                                .padding(.top, Spacing.s2)
                            }

                            // Elapsed timer
                            ElapsedTimerView(startTime: wk.startTime)
                                .padding(.top, 5)

                            // Live stats
                            HStack(spacing: 18) {
                                liveStatView("Volume", WeightFormatter.formatVolume(wk.volume))
                                liveStatView("Sets", "\(wk.completedSets)/\(wk.totalSets)")
                                liveStatView("PRs", "\(wk.prCount)")
                            }
                            .padding(.top, Spacing.s3)
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s5)

                        // Exercise blocks
                        ForEach(Array(wk.exercises.enumerated()), id: \.element.id) { exIdx, exercise in
                            ExerciseBlockView(
                                exercise: exercise,
                                exIdx: exIdx,
                                activeCell: wk.activeCell,
                                editBuffer: wk.editBuffer,
                                onFocus: { setIdx, field in wk.focusCell(exIdx: exIdx, setIdx: setIdx, field: field) },
                                onToggle: { setIdx in
                                    wk.toggleSet(exIdx: exIdx, setIdx: setIdx)
                                    if wk.exercises[exIdx].sets[setIdx].isPR {
                                        appCoordinator.showToast("New weight PR on \(exercise.name)", icon: "flame.fill", tone: .pr)
                                    }
                                },
                                onAddSet: { wk.addSet(exIdx: exIdx) }
                            )
                        }

                        // Empty state prompt
                        if wk.exercises.isEmpty {
                            VStack(spacing: Spacing.s2) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 32))
                                    .foregroundStyle(theme.text3)
                                Text("No exercises yet")
                                    .font(.system(size: TypeScale.body, weight: .semibold))
                                    .foregroundStyle(theme.text)
                                Text("Add your first exercise to start logging.")
                                    .font(.system(size: TypeScale.sub))
                                    .foregroundStyle(theme.text2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Spacing.s4)
                            .padding(.top, Spacing.s8)
                        }

                        // Bottom actions
                        VStack(spacing: Spacing.s3) {
                            Button {
                                showExercisePicker = true
                            } label: {
                                Text("+ Add exercises")
                            }
                            .buttonStyle(.physique(.secondary))

                            Button("Cancel workout") {
                                showCancelConfirm = true
                            }
                            .buttonStyle(.physique(.destructive))
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s5)
                        .padding(.bottom, Spacing.s10)
                    }
                }

                // Keypad
                if wk.activeCell != nil {
                    NumericKeypad(
                        buffer: wk.editBuffer,
                        field: wk.activeCell?.field ?? .weight,
                        onKey: wk.handleKey,
                        onNext: wk.handleNext,
                        onClose: wk.closeKeypad
                    )
                }
            }
        }
        .onAppear {
            guard !wk.hasStarted else { return }
            wk.startWorkout(
                name: appCoordinator.pendingWorkoutName ?? "Quick Workout",
                exercises: appCoordinator.pendingExercises ?? [],
                coached: appCoordinator.pendingCoached,
                coachPlanDayId: appCoordinator.pendingCoachPlanDayId
            )
            appCoordinator.pendingWorkoutName = nil
            appCoordinator.pendingExercises = nil
            appCoordinator.pendingCoached = false
            appCoordinator.pendingCoachPlanDayId = nil
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                wk.addExercise(exercise)
            }
            .environment(\.theme, PhysiqueColors.dark)
            .preferredColorScheme(.dark)
        }
        .confirmationDialog("Cancel this workout?", isPresented: $showCancelConfirm) {
            Button("Discard workout", role: .destructive) {
                appCoordinator.isWorkoutActive = false
            }
            Button("Keep going", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var workoutHeader: some View {
        HStack {
            if wk.isResting {
                RestTimerPill(
                    remaining: wk.restRemaining,
                    total: wk.restTotal,
                    onAdjust: wk.adjustRest,
                    onSkip: wk.skipRest,
                    onTick: wk.restTick
                )
            } else {
                Button {
                    wk.startRest()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "timer")
                            .font(.system(size: 15))
                            .foregroundStyle(theme.text2)
                        Text("Rest")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text)
                    }
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, 9)
                    .background(theme.surface2)
                    .clipShape(Capsule())
                }
            }

            Spacer()

            Button {
                let _ = wk.finishWorkout(context: modelContext)
                appCoordinator.isWorkoutActive = false
                appCoordinator.showToast("Workout saved", icon: "checkmark", tone: .success)
            } label: {
                Text("Finish")
            }
            .buttonStyle(.physique(.success, fullWidth: false, size: .sm))
            .clipShape(Capsule())
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().background(theme.hairline)
        }
    }

    private func liveStatView(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: TypeScale.caption, weight: .semibold))
                .foregroundStyle(theme.text3)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 19, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.text)
        }
    }
}

// MARK: - Elapsed Timer (isolates 1s updates)

struct ElapsedTimerView: View {
    let startTime: Date

    var body: some View {
        TimelineView(.periodic(from: startTime, by: 1)) { context in
            let elapsed = Int(context.date.timeIntervalSince(startTime))
            HStack(spacing: 7) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                Text(TimeFormatter.duration(TimeInterval(elapsed)))
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(Color.accent)
        }
    }
}
