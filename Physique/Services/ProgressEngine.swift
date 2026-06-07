import Foundation
import SwiftData

enum ProgressEngine {
    struct WeekSummary {
        let weekDays: [Bool] // Mon-Sun completion
        let workoutsThisWeek: Int
        let weeklyVolume: Double
        let streakWeeks: Int
        let totalWorkouts: Int
        let prsThisMonth: Int
    }

    static func computeWeekSummary(sessions: [WorkoutSession]) -> WeekSummary {
        let calendar = Calendar.current
        let now = Date()

        // This week's completion
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let thisWeekSessions = sessions.filter { $0.date >= startOfWeek }
        var weekDays = [Bool](repeating: false, count: 7)
        for session in thisWeekSessions {
            let weekday = calendar.component(.weekday, from: session.date)
            // Convert Sunday=1 to Monday=0 index
            let index = weekday == 1 ? 6 : weekday - 2
            if index >= 0 && index < 7 {
                weekDays[index] = true
            }
        }

        // Weekly volume
        let weekVolume = thisWeekSessions.reduce(0.0) { $0 + $1.totalVolume }

        // Streak (count consecutive weeks with at least 1 session)
        var streak = 0
        var checkDate = startOfWeek
        while true {
            let weekStart = checkDate
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let hasSessions = sessions.contains { $0.date >= weekStart && $0.date < weekEnd }
            if hasSessions {
                streak += 1
                checkDate = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        // PRs this month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let prs = sessions.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.prCount }

        return WeekSummary(
            weekDays: weekDays,
            workoutsThisWeek: thisWeekSessions.count,
            weeklyVolume: weekVolume,
            streakWeeks: streak,
            totalWorkouts: sessions.count,
            prsThisMonth: prs
        )
    }

    /// Compute weekly volume for the last N weeks (oldest first)
    static func weeklyVolumeHistory(sessions: [WorkoutSession], weeks: Int = 8) -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        var volumes = [Double](repeating: 0, count: weeks)

        for i in 0..<weeks {
            let weekOffset = weeks - 1 - i
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to:
                calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            ) else { continue }
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            volumes[i] = sessions
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0.0) { $0 + $1.totalVolume }
        }

        return volumes
    }
}
