import Foundation

struct RecordedGame: Codable, Equatable, Sendable {
    var puzzleID: String
    var didWin: Bool
    var guessesUsed: Int
}

struct GameStats: Codable, Equatable, Sendable {
    var games: [RecordedGame] = []

    var gamesPlayed: Int { games.count }

    var gamesWon: Int { games.filter(\.didWin).count }

    var winPercent: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed) * 100).rounded())
    }

    func wins(forGuessCount guessCount: Int) -> Int {
        games.filter { $0.didWin && $0.guessesUsed == guessCount }.count
    }

    var maxDistributionCount: Int {
        (1...6).map(wins(forGuessCount:)).max() ?? 0
    }

    mutating func record(puzzleID: String, outcome: PuzzleProgress.Outcome, guessesUsed: Int) {
        guard outcome != .inProgress, !games.contains(where: { $0.puzzleID == puzzleID }) else { return }
        games.append(
            RecordedGame(
                puzzleID: puzzleID,
                didWin: outcome == .solved,
                guessesUsed: max(guessesUsed, 0)
            )
        )
    }

    mutating func retract(puzzleID: String) {
        games.removeAll { $0.puzzleID == puzzleID }
    }

    mutating func backfill(from progress: [PuzzleProgress]) {
        let known = Set(games.map(\.puzzleID))
        for item in progress where item.isComplete && !known.contains(item.puzzleID) {
            record(puzzleID: item.puzzleID, outcome: item.outcome, guessesUsed: item.guessesUsed)
        }
    }
}
