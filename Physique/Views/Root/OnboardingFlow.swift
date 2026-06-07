import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if vm.step.showsProgressBar {
                    HStack(spacing: Spacing.s4) {
                        Button(action: vm.back) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(theme.text)
                                .frame(width: 36, height: 36)
                                .background(theme.surface2)
                                .clipShape(Circle())
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(theme.surface2)
                                    .frame(height: 5)
                                Capsule()
                                    .fill(Color.accent)
                                    .frame(width: geo.size.width * vm.step.progress, height: 5)
                                    .animation(.easeInOut(duration: 0.3), value: vm.step)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.horizontal, Spacing.s5)
                    .padding(.top, Spacing.s4)
                }

                // Content
                ScrollView {
                    if vm.isBuilding {
                        buildingView
                    } else {
                        stepContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(vm.step)
                    }
                }

                // Bottom CTA
                if !vm.isBuilding {
                    VStack(spacing: 0) {
                        Button(action: handleContinue) {
                            Text(vm.buttonTitle)
                        }
                        .buttonStyle(.physique(.primary))
                        .disabled(!vm.canContinue)
                        .opacity(vm.canContinue ? 1 : 0.4)
                        .padding(.horizontal, Spacing.s5)

                        if vm.step == .welcome {
                            Button("I already have an account") {
                                finishOnboarding()
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text2)
                            .padding(.top, Spacing.s4)
                        }
                    }
                    .padding(.bottom, Spacing.s8)
                    .padding(.top, Spacing.s3)
                }
            }
        }
        .animation(.easeInOut(duration: 0.32), value: vm.step)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch vm.step {
        case .welcome:
            welcomeStep
        case .goal:
            goalStep
        case .level:
            levelStep
        case .schedule:
            scheduleStep
        case .equipment:
            equipmentStep
        case .path:
            pathStep
        case .ready:
            readyStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            // Mark icon
            ZStack {
                RoundedRectangle(cornerRadius: 21)
                    .fill(Color.accent)
                    .frame(width: 76, height: 76)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.onAccent)
            }

            Text("PHYSIQUE")
                .font(.system(size: TypeScale.body, weight: .bold))
                .tracking(3)
                .foregroundStyle(Color.accent)
                .padding(.top, Spacing.s6)

            VStack(spacing: 0) {
                Text("Train with")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(theme.text)
                Text("intention.")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(theme.text2)
            }
            .padding(.top, Spacing.s4)

            Text("The premium logbook for serious lifters \u{2014} fast to log, smart about your progress.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.s5)
                .padding(.horizontal, Spacing.s8)

            Spacer(minLength: 80)
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What\u{2019}s your goal?")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(theme.text)
            Text("We\u{2019}ll shape your training around it.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .padding(.top, Spacing.s2)

            VStack(spacing: Spacing.s3) {
                OptCardView(title: "Build muscle", subtitle: "Hypertrophy \u{2014} moderate reps, steady volume", icon: "dumbbell.fill", isSelected: vm.goal == "Build muscle") { vm.goal = "Build muscle" }
                OptCardView(title: "Get stronger", subtitle: "Lower reps, heavier loads, longer rest", icon: "bolt.fill", isSelected: vm.goal == "Get stronger") { vm.goal = "Get stronger" }
                OptCardView(title: "Lose fat", subtitle: "Higher density, keep the muscle you\u{2019}ve built", icon: "flame.fill", isSelected: vm.goal == "Lose fat") { vm.goal = "Lose fat" }
                OptCardView(title: "Stay healthy", subtitle: "Balanced full-body, sustainable pace", icon: "chart.line.uptrend.xyaxis", isSelected: vm.goal == "Stay healthy") { vm.goal = "Stay healthy" }
            }
            .padding(.top, Spacing.s6)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s6)
    }

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How much have you lifted?")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(theme.text)
            Text("This sets your starting loads and guidance.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .padding(.top, Spacing.s2)

            VStack(spacing: Spacing.s3) {
                OptCardView(title: "New to lifting", subtitle: "Just starting \u{2014} I\u{2019}d like guidance", isSelected: vm.level == "Beginner") { vm.level = "Beginner" }
                OptCardView(title: "Getting back into it", subtitle: "Lifted before, returning after a break", isSelected: vm.level == "Returning") { vm.level = "Returning" }
                OptCardView(title: "Train regularly", subtitle: "Consistent for a year or more", isSelected: vm.level == "Intermediate") { vm.level = "Intermediate" }
                OptCardView(title: "Advanced", subtitle: "I know my numbers and program myself", isSelected: vm.level == "Advanced") { vm.level = "Advanced" }
            }
            .padding(.top, Spacing.s6)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s6)
    }

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Set your rhythm")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(theme.text)
            Text("You can change these anytime.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .padding(.top, Spacing.s2)

            // Days per week
            VStack(spacing: 0) {
                Text("DAYS PER WEEK")
                    .font(.system(size: TypeScale.sub, weight: .bold))
                    .foregroundStyle(theme.text3)
                    .tracking(0.5)

                HStack {
                    Button(action: { vm.daysPerWeek = max(2, vm.daysPerWeek - 1) }) {
                        Text("\u{2212}")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.text)
                            .frame(width: 44, height: 44)
                            .background(theme.surface2)
                            .clipShape(Circle())
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(vm.daysPerWeek)")
                            .font(.system(size: 42, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(theme.text)
                        Text("days / week")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }

                    Spacer()

                    Button(action: { vm.daysPerWeek = min(6, vm.daysPerWeek + 1) }) {
                        Text("+")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.onAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.accent)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, Spacing.s4)
            }
            .card()
            .padding(.top, Spacing.s6)

            // Units
            VStack(alignment: .leading, spacing: 0) {
                Text("UNITS")
                    .font(.system(size: TypeScale.sub, weight: .bold))
                    .foregroundStyle(theme.text3)
                    .tracking(0.5)
                    .padding(.bottom, Spacing.s4)

                HStack(spacing: 4) {
                    ForEach([WeightUnit.kg, .lb], id: \.self) { unit in
                        Button(action: { vm.units = unit }) {
                            Text(unit == .kg ? "Kilograms (kg)" : "Pounds (lb)")
                                .font(.system(size: TypeScale.body, weight: .semibold))
                                .foregroundStyle(vm.units == unit ? .onAccent : theme.text2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(vm.units == unit ? Color.accent : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.full))
                        }
                    }
                }
                .padding(4)
                .background(theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Radius.full))
            }
            .card()
            .padding(.top, Spacing.s3)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s6)
    }

    private var equipmentStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What equipment do you have?")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(theme.text)
            Text("Select all that apply \u{2014} we\u{2019}ll prioritise lifts you can actually do.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .padding(.top, Spacing.s2)

            VStack(spacing: Spacing.s3) {
                ForEach(ExerciseType.allCases) { type in
                    OptCardView(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: vm.equipment.contains(type)
                    ) {
                        if vm.equipment.contains(type) {
                            vm.equipment.remove(type)
                        } else {
                            vm.equipment.insert(type)
                        }
                    }
                }
            }
            .padding(.top, Spacing.s6)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s6)
    }

    private var pathStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How do you want to train?")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(theme.text)
            Text("Switch between these anytime in the Plan tab.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .padding(.top, Spacing.s2)

            VStack(spacing: Spacing.s3) {
                OptCardView(title: "Coach me", subtitle: "AI builds each session and guides your form \u{2014} best if you\u{2019}re newer.", icon: "sparkles", badge: "Recommended", isSelected: vm.path == "coach") { vm.path = "coach" }
                OptCardView(title: "I\u{2019}ll build my own", subtitle: "Create routines and templates yourself.", icon: "clipboard.fill", isSelected: vm.path == "template") { vm.path = "template" }
            }
            .padding(.top, Spacing.s6)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s6)
    }

    private var readyStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.onAccent)
            }

            Text("You\u{2019}re all set")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(theme.text)
                .padding(.top, Spacing.s6)

            Text(vm.path == "coach"
                 ? "Your coach has your first session ready in the Plan tab."
                 : "Build your first routine in the Plan tab whenever you\u{2019}re ready.")
                .font(.system(size: TypeScale.body))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.s3)
                .padding(.horizontal, Spacing.s8)

            // Summary table
            VStack(spacing: 0) {
                summaryRow("Goal", vm.goal ?? "")
                summaryRow("Experience", vm.levelDisplayName)
                summaryRow("Schedule", "\(vm.daysPerWeek) days / week")
                summaryRow("Units", vm.units.rawValue)
                summaryRow("Equipment", vm.equipmentDisplayName)
                summaryRow("Mode", vm.modeDisplayName)
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(theme.hairline, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.s5)
            .padding(.top, Spacing.s6)

            Spacer(minLength: 60)
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
            Spacer()
            Text(value)
                .font(.system(size: TypeScale.sub, weight: .semibold))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
    }

    private var buildingView: some View {
        VStack(spacing: Spacing.s5) {
            Spacer(minLength: 120)

            ZStack {
                Circle()
                    .stroke(Color.accent.opacity(0.2), lineWidth: 3)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accent)
            }

            VStack(spacing: 6) {
                Text("Building your plan")
                    .font(.system(size: TypeScale.title3, weight: .bold))
                    .foregroundStyle(theme.text)
                Text("Tailoring movements to your goal and experience\u{2026}")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - Actions

    private func handleContinue() {
        if vm.step == .ready {
            finishOnboarding()
        } else {
            vm.next()
        }
    }

    private func finishOnboarding() {
        vm.complete(context: modelContext)
        coordinator.showOnboarding = false
    }
}
