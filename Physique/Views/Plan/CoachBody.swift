import SwiftUI

struct CoachBody: View {
    @Environment(\.theme) var theme
    @Environment(AppCoordinator.self) var coordinator
    @State private var coach = CoachService()
    @State private var freeText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rationale card
            if !coach.rationale.isEmpty {
                HStack(alignment: .top, spacing: Spacing.s3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accent)
                    Text(coach.rationale)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                        .lineSpacing(3)
                }
                .padding(Spacing.s4)
                .background(Color.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.accent.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)
            }

            // Control chips
            HStack(spacing: Spacing.s2) {
                PillView(text: coach.goal, tone: .accent)
                PillView(text: coach.level, tone: .neutral)
                PillView(text: "\(coach.minutes) min", tone: .neutral)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            // Generated session
            if let session = coach.currentSession {
                VStack(alignment: .leading, spacing: 0) {
                    Text(session.name)
                        .font(.system(size: TypeScale.title3, weight: .bold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s5)

                    Text("\(session.exercises.count) exercises \u{00B7} ~\(coach.minutes) min")
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                        .foregroundStyle(theme.text3)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.top, Spacing.s1)

                    // Exercise list
                    ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                        CoachExerciseRow(exercise: exercise, number: index + 1)
                    }
                    .padding(.top, Spacing.s3)

                    // Start button
                    Button {
                        coordinator.launchWorkout(
                            name: session.name,
                            exercises: coach.sessionToExercises(),
                            coached: true
                        )
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start coached workout")
                        }
                    }
                    .buttonStyle(.physique(.primary))
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)
                }
            } else if coach.isLoading {
                VStack(spacing: Spacing.s4) {
                    ProgressView()
                        .tint(.accent)
                    Text("Generating your session\u{2026}")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s10)
            }

            // Ask Coach section
            SectionLabel(text: "Ask your coach")
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s3)

            // FAQ chips
            let availableFAQs = CoachService.faqs.enumerated().filter { !coach.askedFAQs.contains($0.offset) }
            if !availableFAQs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(availableFAQs, id: \.offset) { index, faq in
                            Button(faq.question) {
                                coach.askFAQ(index: index)
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, Spacing.s2)
                            .background(theme.surface2)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
            }

            // Chat messages
            ForEach(Array(coach.chatMessages.enumerated()), id: \.offset) { _, msg in
                HStack {
                    if msg.isUser { Spacer() }
                    Text(msg.text)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(msg.isUser ? .onAccent : theme.text)
                        .padding(Spacing.s3)
                        .background(msg.isUser ? Color.accent : theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    if !msg.isUser { Spacer() }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s2)
            }

            // Free text input
            HStack(spacing: Spacing.s2) {
                TextField("Ask anything\u{2026}", text: $freeText)
                    .font(.system(size: TypeScale.body))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

                Button {
                    guard !freeText.isEmpty else { return }
                    coach.askFreeText(freeText)
                    freeText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.onAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.accent)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s3)
        }
        .task {
            if coach.currentSession == nil {
                await coach.generateSession()
            }
        }
    }
}

// MARK: - Coach Exercise Row

struct CoachExerciseRow: View {
    @Environment(\.theme) var theme
    let exercise: CoachExercise
    let number: Int
    @State private var showWhy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.s3) {
                Text("\(number)")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(exercise.name)
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text)

                    Text("\(exercise.sets) \u{00D7} \(exercise.reps)\(exercise.unit.isEmpty ? "" : " \(exercise.unit)")\(exercise.target != nil ? " @ \(WeightFormatter.format(exercise.target!)) lb" : "")")
                        .font(.system(size: TypeScale.sub))
                        .monospacedDigit()
                        .foregroundStyle(theme.text2)

                    // Form cue
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.accent)
                        Text(exercise.cue)
                            .font(.system(size: TypeScale.footnote))
                            .foregroundStyle(Color.accent)
                            .lineSpacing(2)
                    }
                    .padding(.top, Spacing.s1)

                    // Why this?
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showWhy.toggle()
                        }
                    } label: {
                        Text(showWhy ? "Hide" : "Why this?")
                            .font(.system(size: TypeScale.footnote, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                    .padding(.top, Spacing.s1)

                    if showWhy {
                        Text(exercise.why)
                            .font(.system(size: TypeScale.footnote))
                            .foregroundStyle(theme.text2)
                            .lineSpacing(2)
                            .padding(.top, Spacing.s1)
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
        }
    }
}
