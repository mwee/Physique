import Foundation
import SwiftData

@Model
final class ActiveProgram {
    var id: UUID = UUID()
    var programId: String // "531bbb", "gzclp", etc.
    var maxes: [String: Double] = [String: Double]()
    var trainingMaxPercent: Int = 90
    var includeWarmups: Bool = false
    var currentWeek: Int = 0
    var currentDayIndex: Int = 0
    var unitRaw: String = "lb"
    var activatedAt: Date = Date()

    // Training block: maxes stay locked for `blockWeeks`; `weeksInBlock`
    // counts completed weeks and the block-complete review resets it.
    var blockWeeks: Int = 6
    var weeksInBlock: Int = 0
    var blocksCompleted: Int = 0
    var blockStartedAt: Date = Date()
    /// JSON `[MaxesSnapshot]`: the maxes in force from each date, so the
    /// training max can be drawn as a staircase over time.
    var maxesLogData: Data = Data()

    init(
        programId: String,
        maxes: [String: Double] = [:],
        trainingMaxPercent: Int = 90,
        includeWarmups: Bool = false,
        currentWeek: Int = 0,
        unit: WeightUnit = WeightUnit.lb,
        blockWeeks: Int = 6
    ) {
        self.programId = programId
        self.maxes = maxes
        self.trainingMaxPercent = trainingMaxPercent
        self.includeWarmups = includeWarmups
        self.currentWeek = currentWeek
        self.unitRaw = unit.rawValue
        self.blockWeeks = blockWeeks
    }
}

