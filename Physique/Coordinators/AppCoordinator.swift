import SwiftUI
import SwiftData

@Observable
final class AppCoordinator {
    var selectedTab: AppTab = .home
    var isWorkoutActive: Bool = false
    var showOnboarding: Bool = false
    var toast: ToastData?

    // Staged workout to launch into the active-workout cover
    var pendingWorkoutName: String?
    var pendingExercises: [ActiveExercise]?
    var pendingCoached: Bool = false
    var pendingCoachPlanDayId: UUID?
    var pendingAdvancesProgram: Bool = false

    private var toastTask: Task<Void, Never>?

    /// Stage a workout and present the active-workout cover.
    func launchWorkout(name: String, exercises: [ActiveExercise], coached: Bool = false, coachPlanDayId: UUID? = nil, advancesProgram: Bool = false) {
        pendingWorkoutName = name
        pendingExercises = exercises
        pendingCoached = coached
        pendingCoachPlanDayId = coachPlanDayId
        pendingAdvancesProgram = advancesProgram
        isWorkoutActive = true
    }

    /// Start a blank "Quick Workout" with no exercises.
    func launchBlankWorkout() {
        launchWorkout(name: "Quick Workout", exercises: [])
    }

    enum AppTab: String, CaseIterable {
        case home, plan, history, exercises, progress

        var label: String {
            switch self {
            case .home: "Home"
            case .plan: "Plan"
            case .history: "History"
            case .exercises: "Exercises"
            case .progress: "Progress"
            }
        }

        var icon: String {
            switch self {
            case .home: "house.fill"
            case .plan: "calendar"
            case .history: "clock.fill"
            case .exercises: "dumbbell.fill"
            case .progress: "chart.line.uptrend.xyaxis"
            }
        }
    }

    func showToast(_ message: String, icon: String? = nil, tone: PillTone = .neutral) {
        toastTask?.cancel()
        toast = ToastData(message: message, icon: icon, tone: tone)
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                toast = nil
            }
        }
    }

    func checkOnboarding(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        showOnboarding = profiles.isEmpty || !(profiles.first?.hasCompletedOnboarding ?? false)
    }
}
