import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var goal: String?
    var level: String?
    var daysPerWeek: Int = 4
    var units: WeightUnit = .lb
    var equipment: Set<ExerciseType> = []
    var path: String? // "coach" or "template"
    var isBuilding: Bool = false

    enum OnboardingStep: Int, CaseIterable {
        case welcome, goal, level, schedule, equipment, path, ready

        var progress: Double {
            guard self != .welcome, self != .ready else { return 0 }
            return Double(rawValue) / Double(Self.allCases.count - 1)
        }

        var showsProgressBar: Bool {
            self != .welcome && self != .ready
        }
    }

    var canContinue: Bool {
        switch step {
        case .welcome, .schedule, .ready: true
        case .goal: goal != nil
        case .level: level != nil
        case .equipment: !equipment.isEmpty
        case .path: path != nil
        }
    }

    var buttonTitle: String {
        switch step {
        case .welcome: "Get started"
        case .ready: "Enter Physique"
        case .path: "Build my plan"
        default: "Continue"
        }
    }

    func next() {
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        if step == .path {
            isBuilding = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.4))
                isBuilding = false
                step = nextStep
            }
        } else {
            step = nextStep
        }
    }

    func back() {
        guard let prevStep = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prevStep
    }

    func complete(context: ModelContext) {
        let profile = UserProfile(
            goal: goal,
            experienceLevel: level,
            daysPerWeek: daysPerWeek,
            weightUnit: units,
            equipment: Array(equipment),
            trainingMode: path ?? "template",
            hasCompletedOnboarding: true
        )
        context.insert(profile)
        try? context.save()
    }

    var levelDisplayName: String {
        switch level {
        case "Beginner": "New to lifting"
        default: level ?? ""
        }
    }

    var modeDisplayName: String {
        path == "coach" ? "AI Coach" : "Templates"
    }

    var equipmentDisplayName: String {
        guard !equipment.isEmpty else { return "None" }
        return ExerciseType.allCases
            .filter { equipment.contains($0) }
            .map(\.displayName)
            .joined(separator: ", ")
    }
}
