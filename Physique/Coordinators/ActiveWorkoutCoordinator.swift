import SwiftUI
import SwiftData

@Observable
final class ActiveWorkoutCoordinator {
    var workoutName: String = "Morning Workout"
    var exercises: [ActiveExercise] = []
    var isCoached: Bool = false
    var startTime: Date = Date()
    var hasStarted: Bool = false

    // Edit state
    var activeCell: CellAddress?
    var editBuffer: String = ""
    var isFreshInput: Bool = true

    // Rest timer
    var isResting: Bool = false
    var restTotal: Int = 90
    var restRemaining: Int = 0

    // Notes
    var notes: String = ""

    struct CellAddress: Equatable {
        let exIdx: Int
        let setIdx: Int
        let field: CellField
    }

    enum CellField: String {
        case weight = "w"
        case reps = "r"
    }

    // MARK: - Computed

    var volume: Double {
        WorkoutEngine.calculateVolume(exercises: exercises)
    }

    var completedSets: Int {
        WorkoutEngine.completedSets(exercises: exercises)
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var prCount: Int {
        WorkoutEngine.prCount(exercises: exercises)
    }

    var elapsedSeconds: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    // MARK: - Cell Editing

    func focusCell(exIdx: Int, setIdx: Int, field: CellField) {
        // Commit current buffer first
        commitBuffer()

        let set = exercises[exIdx].sets[setIdx]
        let currentValue = field == .weight ? set.weight : Double(set.reps)
        activeCell = CellAddress(exIdx: exIdx, setIdx: setIdx, field: field)
        editBuffer = currentValue == 0 ? "" : WeightFormatter.format(currentValue)
        isFreshInput = true
    }

    func handleKey(_ key: String) {
        switch key {
        case "back":
            editBuffer = String(editBuffer.dropLast())
        case ".":
            if !editBuffer.contains(".") {
                editBuffer = editBuffer.isEmpty ? "0." : editBuffer + "."
            }
        default:
            if isFreshInput {
                editBuffer = key
                isFreshInput = false
            } else {
                if editBuffer.count < 6 {
                    editBuffer += key
                }
            }
        }
        isFreshInput = false
    }

    func handleNext() {
        guard let cell = activeCell else { return }
        commitBuffer()

        if cell.field == .weight {
            // Move to reps
            focusCell(exIdx: cell.exIdx, setIdx: cell.setIdx, field: .reps)
        } else {
            // Move to next set's weight, or close keypad
            let ex = exercises[cell.exIdx]
            if cell.setIdx + 1 < ex.sets.count {
                focusCell(exIdx: cell.exIdx, setIdx: cell.setIdx + 1, field: .weight)
            } else {
                commitBuffer()
                activeCell = nil
            }
        }
    }

    func closeKeypad() {
        commitBuffer()
        activeCell = nil
    }

    private func commitBuffer() {
        guard let cell = activeCell else { return }
        let value = Double(editBuffer) ?? 0
        if cell.field == .weight {
            exercises[cell.exIdx].sets[cell.setIdx].weight = value
        } else {
            exercises[cell.exIdx].sets[cell.setIdx].reps = Int(value)
        }
    }

    // MARK: - Set Actions

    func toggleSet(exIdx: Int, setIdx: Int) {
        closeKeypad()
        let wasDone = exercises[exIdx].sets[setIdx].isDone
        exercises[exIdx].sets[setIdx].isDone = !wasDone

        if !wasDone {
            // Check for PR
            let set = exercises[exIdx].sets[setIdx]
            let exercise = exercises[exIdx].exercise
            if WorkoutEngine.isPR(weight: set.weight, reps: set.reps, exercise: exercise) {
                exercises[exIdx].sets[setIdx].isPR = true
            }
            // Start rest timer
            startRest()
        } else {
            exercises[exIdx].sets[setIdx].isPR = false
        }
    }

    func addExercise(_ exercise: Exercise) {
        closeKeypad()
        let active = ActiveExercise(
            exId: exercise.id,
            name: exercise.name,
            exercise: exercise,
            note: exercise.note,
            sets: [ActiveSet(type: .working(1), weight: 0, reps: 0)]
        )
        exercises.append(active)
    }

    func removeExercise(exIdx: Int) {
        closeKeypad()
        guard exercises.indices.contains(exIdx) else { return }
        exercises.remove(at: exIdx)
    }

    func removeSet(exIdx: Int, setIdx: Int) {
        closeKeypad()
        guard exercises.indices.contains(exIdx),
              exercises[exIdx].sets.indices.contains(setIdx) else { return }
        exercises[exIdx].sets.remove(at: setIdx)
    }

    func addSet(exIdx: Int) {
        let ex = exercises[exIdx]
        let lastSet = ex.sets.last
        let workingCount = ex.sets.filter { !$0.type.isWarmup }.count
        let newSet = ActiveSet(
            type: .working(workingCount + 1),
            prevWeight: lastSet?.prevWeight,
            prevReps: lastSet?.prevReps,
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 0
        )
        exercises[exIdx].sets.append(newSet)
    }

    // MARK: - Rest Timer

    func startRest() {
        restRemaining = restTotal
        isResting = true
    }

    func adjustRest(_ delta: Int) {
        restRemaining = max(0, restRemaining + delta)
        if restRemaining > restTotal { restTotal = restRemaining }
    }

    func skipRest() {
        isResting = false
        restRemaining = 0
    }

    func restTick() {
        guard isResting else { return }
        restRemaining -= 1
        if restRemaining <= 0 {
            isResting = false
        }
    }

    // MARK: - Start / Finish

    func startWorkout(name: String, exercises: [ActiveExercise], coached: Bool = false) {
        self.workoutName = name
        self.exercises = exercises
        self.isCoached = coached
        self.startTime = Date()
        self.activeCell = nil
        self.editBuffer = ""
        self.notes = ""
        self.isResting = false
        self.hasStarted = true
    }

    /// Start a blank "Quick Workout" with no exercises — user adds them live.
    func startBlank() {
        startWorkout(name: "Quick Workout", exercises: [])
    }

    func startEmpty() {
        // Start with the default workout from seed data
        startWorkout(name: "Morning Workout", exercises: SampleWorkout.exercises)
    }

    func finishWorkout(context: ModelContext) -> WorkoutSession {
        let duration = Date().timeIntervalSince(startTime)
        return WorkoutEngine.saveWorkout(
            name: workoutName,
            exercises: exercises,
            duration: duration,
            context: context
        )
    }
}

// MARK: - Sample workout for demo/testing

enum SampleWorkout {
    static var exercises: [ActiveExercise] {
        [
            ActiveExercise(
                exId: "deadlift", name: "Deadlift", note: "Watch back rounding",
                sets: [
                    ActiveSet(type: .warmup, prevWeight: 135, prevReps: 5, weight: 135, reps: 5),
                    ActiveSet(type: .working(1), prevWeight: 220, prevReps: 3, weight: 220, reps: 3),
                    ActiveSet(type: .working(2), prevWeight: 265, prevReps: 1, weight: 265, reps: 1),
                    ActiveSet(type: .working(3), prevWeight: 300, prevReps: 5, weight: 285, reps: 5),
                ]
            ),
            ActiveExercise(
                exId: "bench", name: "Bench Press",
                sets: [
                    ActiveSet(type: .warmup, prevWeight: 90, prevReps: 8, weight: 90, reps: 8),
                    ActiveSet(type: .working(1), prevWeight: 175, prevReps: 6, weight: 175, reps: 6),
                    ActiveSet(type: .working(2), prevWeight: 200, prevReps: 4, weight: 200, reps: 4),
                    ActiveSet(type: .working(3), prevWeight: 210, prevReps: 3, weight: 210, reps: 3),
                ]
            ),
            ActiveExercise(
                exId: "row", name: "Barbell Row",
                sets: [
                    ActiveSet(type: .working(1), prevWeight: 155, prevReps: 8, weight: 155, reps: 8),
                    ActiveSet(type: .working(2), prevWeight: 175, prevReps: 6, weight: 175, reps: 6),
                    ActiveSet(type: .working(3), prevWeight: 185, prevReps: 6, weight: 185, reps: 6),
                ]
            ),
        ]
    }
}
