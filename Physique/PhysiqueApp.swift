import SwiftUI
import SwiftData

@main
struct PhysiqueApp: App {
    @State private var coordinator = AppCoordinator()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            ExerciseRecord.self,
            WorkoutSession.self,
            SessionExercise.self,
            ExerciseSet.self,
            UserProfile.self,
            BodyweightEntry.self,
            ActiveProgram.self,
            WorkoutTemplate.self,
            TemplateItem.self,
            OneRepMaxEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()

                if coordinator.showOnboarding {
                    OnboardingFlow()
                        .transition(.opacity)
                }
            }
            .environment(coordinator)
            .environment(\.theme, PhysiqueColors.dark)
            .toast(coordinator.toast)
            .preferredColorScheme(.dark)
            .onAppear {
                let ctx = sharedModelContainer.mainContext
                SeedDataService.seedIfNeeded(context: ctx)
                coordinator.checkOnboarding(context: ctx)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
