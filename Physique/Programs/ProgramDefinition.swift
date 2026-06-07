import Foundation

// MARK: - Program Template Types (plain Swift, not SwiftData)

struct ProgramDefinition: Identifiable {
    let id: String
    let name: String
    let author: String
    let glyph: String
    var featured: Bool = false
    let tags: [String]
    let days: String
    let cycle: String
    let basis: WeightBasis
    let layout: SpreadsheetLayout
    let blurb: String
    let cycleWeeks: Int
    var weekNames: [String]?
    let split: [SplitDay]
    let liftIds: [String]
    let blocks: [ProgramBlock]
    var warmup: WarmupConfig?
    var supplemental: SupplementalConfig?
    let progressNote: String
    var setHeads: [String]?
    // Flags
    var waved: Bool = false
    var useWeekBlock: Bool = false
    var weekScale: WeekScaleType?
    var single: Bool = false
    var note: String?
}

// MARK: - Enums

enum WeightBasis {
    case trainingMax
    case oneRepMax
}

enum SpreadsheetLayout {
    case table
    case straight
}

enum WeekScaleType {
    case multiplicative
    case additive
}

// MARK: - Split

struct SplitDay: Identifiable {
    let id = UUID()
    let name: String
    var sub: String?
    var ids: [String] = []
    var items: [SplitItem]?
    var b: Int?
    var light: Bool = false
}

struct SplitItem {
    let id: String
    let b: Int
}

// MARK: - Blocks & Sets

struct ProgramBlock: Identifiable {
    let id = UUID()
    let label: String
    var sub: String?
    var sets: [ProgramSet]?
    var straight: StraightConfig?
}

struct ProgramSet {
    let p: Double  // percentage
    let r: Int     // reps
    var amrap: Bool = false
    var top: Bool = false
    var pr: Bool = false
}

struct StraightConfig {
    let count: Int
    let r: Int
    let p: Double
    var amrap: Bool = false
    var pr: Bool = false
}

// MARK: - Warmup & Supplemental

struct WarmupConfig {
    let sets: [ProgramSet]
}

struct SupplementalConfig {
    let label: String
    let detail: String
    let p: Double
}
