import SwiftUI

struct MainTabView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeScreen()
            }

            Tab("Plan", systemImage: "calendar", value: .plan) {
                PlanScreen()
            }

            Tab("History", systemImage: "clock.fill", value: .history) {
                HistoryScreen()
            }

            Tab("Exercises", systemImage: "dumbbell.fill", value: .exercises) {
                ExerciseLibraryScreen()
            }

            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis", value: .progress) {
                ProgressScreen()
            }
        }
        .tint(.accent)
        .fullScreenCover(isPresented: $coordinator.isWorkoutActive) {
            ActiveWorkoutScreen()
                .environment(coordinator)
                .environment(\.theme, PhysiqueColors.dark)
                .preferredColorScheme(.dark)
        }
    }
}
