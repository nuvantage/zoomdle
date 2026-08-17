import Foundation

struct StreakStats: Codable, Equatable, Sendable {
    var current: Int = 0
    var best: Int = 0
    var lastCompletedDay: String?

    mutating func applyCompletion(outcome: PuzzleProgress.Outcome, on date: Date) {
        guard outcome != .inProgress else { return }

        let day = Puzzle.dayString(from: date)
        if lastCompletedDay == day {
            return
        }

        let consecutiveWithPrevious = isConsecutive(to: day)

        switch outcome {
        case .solved:
            current = consecutiveWithPrevious ? current + 1 : 1
            best = max(best, current)
        case .failed:
            current = 0
        case .inProgress:
            return
        }

        lastCompletedDay = day
    }

    mutating func clearCompletion(on date: Date) {
        let day = Puzzle.dayString(from: date)
        guard lastCompletedDay == day else { return }
        if current > 0 {
            current -= 1
        }
        lastCompletedDay = nil
    }

    private func isConsecutive(to day: String) -> Bool {
        guard
            let lastDay = lastCompletedDay,
            let lastDate = Puzzle.date(fromJSON: lastDay),
            let thisDate = Puzzle.date(fromJSON: day),
            let gap = Calendar.current.dateComponents([.day], from: lastDate, to: thisDate).day
        else {
            return false
        }
        return gap == 1
    }
}

@MainActor
protocol StreakStoring {
    func load() -> StreakStats
    func recordCompletion(outcome: PuzzleProgress.Outcome, on date: Date) -> StreakStats
    func clearCompletion(on date: Date) -> StreakStats
}

@MainActor
final class UserDefaultsStreakStore: StreakStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "streakStats.v1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> StreakStats {
        guard let data = defaults.data(forKey: key),
              let stats = try? JSONDecoder().decode(StreakStats.self, from: data) else {
            return StreakStats()
        }
        return stats
    }

    func recordCompletion(outcome: PuzzleProgress.Outcome, on date: Date) -> StreakStats {
        var stats = load()
        stats.applyCompletion(outcome: outcome, on: date)
        save(stats)
        return stats
    }

    func clearCompletion(on date: Date) -> StreakStats {
        var stats = load()
        stats.clearCompletion(on: date)
        save(stats)
        return stats
    }

    private func save(_ stats: StreakStats) {
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: key)
        }
    }
}

@MainActor
final class InMemoryStreakStore: StreakStoring {
    private var stats: StreakStats

    init(stats: StreakStats = StreakStats()) {
        self.stats = stats
    }

    func load() -> StreakStats {
        stats
    }

    func recordCompletion(outcome: PuzzleProgress.Outcome, on date: Date) -> StreakStats {
        stats.applyCompletion(outcome: outcome, on: date)
        return stats
    }

    func clearCompletion(on date: Date) -> StreakStats {
        stats.clearCompletion(on: date)
        return stats
    }
}
