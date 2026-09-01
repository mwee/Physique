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
    /// Best single per big lift, keyed by lift id; optional, entered as text.
    var maxes: [String: String] = [:]
    var path: String? // "coach" or "template"
    var isBuilding: Bool = false

    private let coachService = CoachPlanService()

    enum OnboardingStep: Int, CaseIterable {
        case welcome, goal, level, schedule, equipment, maxes, path, ready

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
        case .welcome, .schedule, .maxes, .ready: true
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
        case .maxes: enteredMaxes.isEmpty ? "Skip for now" : "Continue"
        default: "Continue"
        }
    }

    func next(context: ModelContext) {
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        if step == .path && path == "coach" {
            // Coach path: generate and persist a real weekly plan before advancing.
            isBuilding = true
            Task { @MainActor in
                await buildPlan(context: context)
                isBuilding = false
                step = nextStep
            }
        } else {
            step = nextStep
        }
    }

    @MainActor
    private func buildPlan(context: ModelContext) async {
        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let oneRepMaxes = (try? context.fetch(FetchDescriptor<OneRepMaxEntry>())) ?? []
        let request = CoachPlanService.makeRequest(
            goal: goal ?? "Build muscle",
            level: level ?? "Beginner",
            daysPerWeek: daysPerWeek,
            equipment: Array(equipment),
            unit: units,
            exercises: exercises,
            oneRepMaxes: oneRepMaxes
        )
        await coachService.generateAndStore(from: request, context: context)
    }

    func back() {
        guard let prevStep = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prevStep
    }

    static let bigLifts: [(id: String, name: String)] = [
        ("squat", "Back Squat"), ("bench", "Bench Press"), ("deadlift", "Deadlift"), ("ohp", "Overhead Press"),
    ]

    /// Parsed, positive maxes the user typed.
    var enteredMaxes: [(id: String, name: String, weight: Double)] {
        Self.bigLifts.compactMap { lift in
            guard let text = maxes[lift.id], let weight = Double(text.trimmingCharacters(in: .whitespaces)), weight > 0 else { return nil }
            return (lift.id, lift.name, weight)
        }
    }

    var maxesDisplayName: String {
        let entered = enteredMaxes
        guard !entered.isEmpty else { return "Skipped" }
        return entered.map { WeightFormatter.format($0.weight) }.joined(separator: " / ")
    }

    func complete(context: ModelContext) {
        // Stated maxes are tested data points in the e1RM stream.
        for max in enteredMaxes {
            context.insert(OneRepMaxEntry(exerciseId: max.id, exerciseName: max.name, weight: max.weight, unit: units, date: Date()))
        }
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
