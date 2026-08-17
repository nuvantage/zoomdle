import Foundation

enum ShareResult {
    static let wrong = "🟥"
    static let correct = "🟩"
    static let unused = "⬜"

    static func grid(guessesUsed: Int, didSolve: Bool, maxGuesses: Int = 6) -> String {
        let maxSlots = max(maxGuesses, 1)

        if didSolve {
            let safeUsed = min(max(guessesUsed, 1), maxSlots)
            let wrongCount = max(safeUsed - 1, 0)
            let unusedCount = max(maxSlots - safeUsed, 0)
            return String(repeating: wrong, count: wrongCount)
                + correct
                + String(repeating: unused, count: unusedCount)
        }

        return String(repeating: wrong, count: maxSlots)
    }

    static func score(guessesUsed: Int, didSolve: Bool, maxGuesses: Int = 6) -> String {
        didSolve ? "\(guessesUsed)/\(maxGuesses)" : "X/\(maxGuesses)"
    }

    static func text(puzzleNumber: Int, guessesUsed: Int, didSolve: Bool, maxGuesses: Int = 6) -> String {
        let squares = grid(guessesUsed: guessesUsed, didSolve: didSolve, maxGuesses: maxGuesses)
        let scoreLine = score(guessesUsed: guessesUsed, didSolve: didSolve, maxGuesses: maxGuesses)
        return "\(squares) Zoomdle #\(puzzleNumber): \(scoreLine)"
    }
}
