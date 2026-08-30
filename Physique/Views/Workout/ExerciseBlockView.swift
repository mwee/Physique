import SwiftUI

struct ExerciseBlockView: View {
    @Environment(\.theme) var theme
    let exercise: ActiveExercise
    let exIdx: Int
    let activeCell: ActiveWorkoutCoordinator.CellAddress?
    let editBuffer: String
    let onFocus: (Int, ActiveWorkoutCoordinator.CellField) -> Void
    let onToggle: (Int) -> Void
    let onAddSet: () -> Void
    @State private var showDemo = false

    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack {
                Text(exercise.name)
                    .font(.system(size: TypeScale.callout, weight: .bold))
                    .foregroundStyle(Color.accent)
                Spacer()
                HStack(spacing: Spacing.s2) {
                    if !ExerciseMediaService.frames(for: exercise.exId).isEmpty {
                        Button {
                            showDemo = true
                        } label: {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 17))
                        }
                        .accessibilityLabel("Watch \(exercise.name) demo")
                    }
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.accent)
            }
            .sheet(isPresented: $showDemo) {
                ExerciseDemoSheet(exerciseId: exercise.exId, exerciseName: exercise.name, cue: exercise.cue)
                    .environment(\.theme, PhysiqueColors.dark)
                    .preferredColorScheme(.dark)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)
            .padding(.bottom, Spacing.s2)

            // Note banner
            if let note = exercise.note {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                    Text(note)
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                }
                .foregroundStyle(Color.prGold)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.prGold.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                .padding(.horizontal, Spacing.s4)
                .padding(.bottom, Spacing.s2)
            }

            // AI cue banner
            if let cue = exercise.cue {
                HStack(alignment: .top, spacing: Spacing.s2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text(cue)
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                        .lineSpacing(2)
                }
                .foregroundStyle(Color.accent)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accent.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
                .padding(.horizontal, Spacing.s4)
                .padding(.bottom, Spacing.s2)
            }

            // Column headers
            HStack(spacing: 7) {
                Text("Set")
                    .frame(width: 30, alignment: .leading)
                Text("Previous")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("lb")
                    .frame(width: 62, alignment: .center)
                Text("Reps")
                    .frame(width: 54, alignment: .center)
                Spacer()
                    .frame(width: 38)
            }
            .font(.system(size: TypeScale.caption, weight: .semibold))
            .foregroundStyle(theme.text3)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, Spacing.s4)
            .frame(height: 30)

            // Set rows
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIdx, set in
                SetRowView(
                    set: set,
                    isActive: activeCell?.exIdx == exIdx && activeCell?.setIdx == setIdx,
                    activeField: activeCell?.exIdx == exIdx && activeCell?.setIdx == setIdx ? activeCell?.field : nil,
                    editBuffer: editBuffer,
                    onFocusWeight: { onFocus(setIdx, .weight) },
                    onFocusReps: { onFocus(setIdx, .reps) },
                    onToggle: { onToggle(setIdx) }
                )
            }

            // Add set button
            Button(action: onAddSet) {
                Text("+ Add set")
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s2)
        }
        .padding(.top, Spacing.s2)
    }
}
