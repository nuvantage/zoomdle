import Foundation

@MainActor
protocol GameStatsStoring {
    func load() -> GameStats
    func record(puzzleID: String, outcome: PuzzleProgress.Outcome, guessesUsed: Int) -> GameStats
    func retract(puzzleID: String) -> GameStats
    func backfill(from progress: [PuzzleProgress]) -> GameStats
}

@MainActor
final class UserDefaultsGameStatsStore: GameStatsStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "gameStats.v1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> GameStats {
        guard let data = defaults.data(forKey: key),
              let stats = try? JSONDecoder().decode(GameStats.self, from: data) else {
            return GameStats()
        }
        return stats
    }

    func record(puzzleID: String, outcome: PuzzleProgress.Outcome, guessesUsed: Int) -> GameStats {
        var stats = load()
        stats.record(puzzleID: puzzleID, outcome: outcome, guessesUsed: guessesUsed)
        save(stats)
        return stats
    }

    func retract(puzzleID: String) -> GameStats {
        var stats = load()
        stats.retract(puzzleID: puzzleID)
        save(stats)
        return stats
    }

    func backfill(from progress: [PuzzleProgress]) -> GameStats {
        var stats = load()
        stats.backfill(from: progress)
        save(stats)
        return stats
    }

    private func save(_ stats: GameStats) {
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: key)
        }
    }
}

@MainActor
final class InMemoryGameStatsStore: GameStatsStoring {
    private var stats: GameStats

    init(stats: GameStats = GameStats()) {
        self.stats = stats
    }

    func load() -> GameStats {
        stats
    }

    func record(puzzleID: String, outcome: PuzzleProgress.Outcome, guessesUsed: Int) -> GameStats {
        stats.record(puzzleID: puzzleID, outcome: outcome, guessesUsed: guessesUsed)
        return stats
    }

    func retract(puzzleID: String) -> GameStats {
        stats.retract(puzzleID: puzzleID)
        return stats
    }

    func backfill(from progress: [PuzzleProgress]) -> GameStats {
        stats.backfill(from: progress)
        return stats
    }
}
