import Foundation

enum SessionBuilder {

    /// Build an array of ActiveExercise for a given program day.
    ///
    /// - Parameters:
    ///   - program: The static program template.
    ///   - config: The user's active program (maxes, current week, etc.).
    ///   - dayIndex: Which split day to generate (0-based).
    /// - Returns: An array of `ActiveExercise` ready for the workout screen.
    static func buildSession(
        program: ProgramDefinition,
        config: ActiveProgram,
        dayIndex: Int
    ) -> [ActiveExercise] {
        guard dayIndex >= 0, dayIndex < program.split.count else { return [] }

        let splitDay = program.split[dayIndex]
        let unit = config.unit
        let tmPct = config.trainingMaxPercent
        let week = config.currentWeek

        // Determine which lift IDs this day trains and which block each uses.
        let liftAssignments: [(liftId: String, blockIndex: Int)] = resolveLiftAssignments(
            splitDay: splitDay,
            program: program,
            dayIndex: dayIndex
        )

        var exercises: [ActiveExercise] = []

        for (liftId, blockIndex) in liftAssignments {
            guard blockIndex < program.blocks.count else { continue }
            guard let oneRM = config.maxes[liftId], oneRM > 0 else { continue }

            let block = program.blocks[resolvedBlockIndex(blockIndex, program: program, week: week)]
            let exerciseName = ExerciseCatalog.displayName(for: liftId)

            var sets: [ActiveSet] = []
            var setCounter = 0

            // Warmup sets
            if config.includeWarmups, let warmup = program.warmup {
                for ws in warmup.sets {
                    let w = scaledSetWeight(oneRM: oneRM, pct: ws.p, program: program,
                                            tmPct: tmPct, unit: unit, week: week)
                    sets.append(ActiveSet(type: .warmup, weight: w, reps: ws.r))
                }
            }

            // Working sets
            if let blockSets = block.sets {
                // Table layout: explicit set list
                for ps in blockSets {
                    setCounter += 1
                    let w = scaledSetWeight(oneRM: oneRM, pct: ps.p, program: program,
                                            tmPct: tmPct, unit: unit, week: week)
                    sets.append(ActiveSet(type: .working(setCounter), weight: w, reps: ps.r))
                }
            } else if let straight = block.straight {
                // Straight layout: repeated identical sets
                let w = scaledSetWeight(oneRM: oneRM, pct: straight.p, program: program,
                                        tmPct: tmPct, unit: unit, week: week)
                for i in 1...straight.count {
                    sets.append(ActiveSet(type: .working(i), weight: w, reps: straight.r))
                }
            }

            // Supplemental sets
            if let supp = program.supplemental {
                let suppWeight = scaledSetWeight(oneRM: oneRM, pct: supp.p, program: program,
                                                 tmPct: tmPct, unit: unit, week: week)
                for i in 1...5 {
                    sets.append(ActiveSet(type: .working(setCounter + i), weight: suppWeight, reps: 10))
                }
            }

            exercises.append(ActiveExercise(
                exId: liftId,
                name: exerciseName,
                note: block.sub,
                sets: sets
            ))
        }

        return exercises
    }

    // MARK: - Helpers

    /// Determine lift IDs and their corresponding block indices for a split day.
    private static func resolveLiftAssignments(
        splitDay: SplitDay,
        program: ProgramDefinition,
        dayIndex: Int
    ) -> [(liftId: String, blockIndex: Int)] {
        // If the split day has explicit items with block indices, use those.
        // (e.g. GZCLP where each day pairs lifts with specific tiers)
        if let items = splitDay.items {
            return items.map { (liftId: $0.id, blockIndex: $0.b) }
        }
        // If the day has an explicit block override, use it.
        // Otherwise, map the day index to the block index (e.g. Texas Method:
        // Mon=block 0 Volume, Wed=block 1 Recovery, Fri=block 2 Intensity).
        if !splitDay.ids.isEmpty {
            let blockIdx = splitDay.b ?? dayIndex
            return splitDay.ids.map { (liftId: $0, blockIndex: blockIdx) }
        }
        // Single-lift programs (e.g. Smolov Jr): one lift per day,
        // each day maps to its own block (Day 0=6x6, Day 1=7x5, etc.).
        if program.single {
            return program.liftIds.map { (liftId: $0, blockIndex: dayIndex) }
        }
        return []
    }

    /// For waved programs using useWeekBlock, the block index is the current week.
    /// Otherwise, return the original block index.
    private static func resolvedBlockIndex(
        _ blockIndex: Int,
        program: ProgramDefinition,
        week: Int
    ) -> Int {
        if program.useWeekBlock {
            // In programs like 5/3/1 where each week maps to a different block
            return min(week, program.blocks.count - 1)
        }
        return blockIndex
    }

    /// Calculate a set weight with optional week scaling applied.
    private static func scaledSetWeight(
        oneRM: Double,
        pct: Double,
        program: ProgramDefinition,
        tmPct: Int,
        unit: WeightUnit,
        week: Int
    ) -> Double {
        let base = ProgramEngine.setWeight(
            oneRM: oneRM,
            percentage: pct,
            program: program,
            tmPct: tmPct,
            unit: unit
        )
        // Apply week scaling for programs that ramp over weeks (Madcow, Smolov Jr)
        if program.weekScale != nil {
            return ProgramEngine.scaleForWeek(program: program, weight: base, week: week, unit: unit)
        }
        return base
    }
}
