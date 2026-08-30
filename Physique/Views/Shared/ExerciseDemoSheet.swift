import SwiftUI

/// Quick-reference demo for one exercise: looping animation + form steps.
/// Reachable from the plan screen and mid-workout, so it presents at a
/// medium detent first — enough to watch the movement without losing context.
struct ExerciseDemoSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let exerciseId: String
    let exerciseName: String
    var cue: String?

    private var frames: [String] { ExerciseMediaService.frames(for: exerciseId) }
    private var instructions: [String] { ExerciseMediaService.instructions(for: exerciseId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !frames.isEmpty {
                        ExerciseAnimationView(frames: frames)
                            .padding(.horizontal, Spacing.s4)
                            .padding(.top, Spacing.s3)
                    } else {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "video.slash")
                                .foregroundStyle(theme.text3)
                            Text("No demonstration available for this exercise yet.")
                                .font(.system(size: TypeScale.sub))
                                .foregroundStyle(theme.text2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s3)
                    }

                    if let cue, !cue.isEmpty {
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
                        .padding(.top, Spacing.s3)
                    }

                    if !instructions.isEmpty {
                        SectionLabel(text: "How to perform")
                            .padding(.top, Spacing.s5)
                            .padding(.bottom, Spacing.s3)

                        VStack(alignment: .leading, spacing: Spacing.s4) {
                            ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: Spacing.s3) {
                                    Text("\(index + 1)")
                                        .font(.system(size: TypeScale.footnote, weight: .bold))
                                        .monospacedDigit()
                                        .foregroundStyle(Color.accent)
                                        .frame(width: 22, height: 22)
                                        .background(theme.accentTint)
                                        .clipShape(Circle())
                                    Text(step)
                                        .font(.system(size: TypeScale.sub))
                                        .foregroundStyle(theme.text2)
                                        .lineSpacing(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .card()
                        .padding(.horizontal, Spacing.s4)
                    }
                }
                .padding(.bottom, Spacing.s8)
            }
            .background(theme.bg)
            .navigationTitle(exerciseName)
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
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
