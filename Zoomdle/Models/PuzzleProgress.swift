import Foundation

struct PuzzleProgress: Codable, Equatable, Sendable {
    enum Outcome: String, Codable, Sendable {
        case inProgress
        case solved
        case failed
    }

    var puzzleID: String
    var guesses: [String]
    var outcome: Outcome

    var guessesUsed: Int { guesses.count }
    var isComplete: Bool { outcome != .inProgress }

    static func fresh(puzzleID: String) -> PuzzleProgress {
        PuzzleProgress(puzzleID: puzzleID, guesses: [], outcome: .inProgress)
    }
}
