import Foundation
import SwiftData

/// A user-authored %TM program: named days of (lift, sets, reps, %TM) rows
/// plus 2-week waves that shift the percentages as the program progresses.
@Model
final class CustomProgram {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var daysData: Data = Data()
    var wavePcts: [Int] = [70, 80, 90]

    init(name: String, days: [CustomProgramDay], wavePcts: [Int]) {
        self.name = name
        self.wavePcts = wavePcts
        self.daysData = (try? JSONEncoder().encode(days)) ?? Data()
    }
}

struct CustomProgramDay: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var rows: [CustomProgramRow]
}

struct CustomProgramRow: Codable, Identifiable {
    var id: UUID = UUID()
    var liftId: String
    var sets: Int
    var reps: Int
    var pct: Int // %TM in wave 1
}

extension CustomProgram {
    var days: [CustomProgramDay] {
        get { (try? JSONDecoder().decode([CustomProgramDay].self, from: daysData)) ?? [] }
        set { daysData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// The id stored on `ActiveProgram.programId` when this program is activated.
    var programId: String { "custom-\(id.uuidString)" }

    /// Builds a runtime `ProgramDefinition` for the given 0-based week so the
    /// existing `SessionBuilder` path works unchanged. Later waves shift every
    /// row's %TM by the wave's offset from wave 1 (70/80/90 → +0/+10/+20).
    func definition(forWeek week: Int) -> ProgramDefinition {
        let days = self.days
        let waves = wavePcts.isEmpty ? [70] : wavePcts
        let waveIndex = min(max(0, week) / 2, waves.count - 1)
        let offset = waves[waveIndex] - waves[0]

        var blocks: [ProgramBlock] = []
        var split: [SplitDay] = []
        var liftIds: [String] = []

        for day in days {
            var items: [SplitItem] = []
            for row in day.rows {
                let pct = Double(min(100, max(1, row.pct + offset))) / 100.0
                blocks.append(ProgramBlock(
                    label: "\(row.sets)\u{00D7}\(row.reps)",
                    straight: StraightConfig(count: max(1, row.sets), r: max(1, row.reps), p: pct)
                ))
                items.append(SplitItem(id: row.liftId, b: blocks.count - 1))
                if !liftIds.contains(row.liftId) { liftIds.append(row.liftId) }
            }
            split.append(SplitDay(name: day.name, items: items))
        }

        let waveSummary = waves.map { "\($0)%" }.joined(separator: " \u{2192} ")
        return ProgramDefinition(
            id: programId,
            name: name,
            author: "You",
            glyph: "square.and.pencil",
            tags: ["Custom"],
            days: "\(days.count) days",
            cycle: "\(waves.count * 2)-week wave",
            basis: .trainingMax,
            layout: .straight,
            blurb: "Your own program, authored in %TM. Weights are computed from your training maxes and wave through \(waveSummary) in 2-week blocks.",
            cycleWeeks: waves.count * 2,
            split: split,
            liftIds: liftIds,
            blocks: blocks,
            progressNote: "Each 2-week wave raises the working percentage: \(waveSummary). After the last wave, log new maxes and restart the cycle."
        )
    }
}
