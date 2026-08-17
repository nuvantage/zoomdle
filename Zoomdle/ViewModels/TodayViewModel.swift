import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    static let maxGuesses = 6
    static let maxRevealLevel = 5

    private let puzzleService: any PuzzleServing
    private let progressStore: any PuzzleProgressStoring
    private let wordListService: any WordListServing
    private let streakStore: any StreakStoring
    private let presetPuzzle: Puzzle?

    var puzzle: Puzzle?
    var guessText = ""
    var guesses: [String] = []
    var outcome: PuzzleProgress.Outcome = .inProgress
    var isLoading: Bool
    var errorMessage: String?
    var streakStats = StreakStats()

    var guessesUsed: Int { guesses.count }
    var isComplete: Bool { outcome != .inProgress }
    var currentStreak: Int { streakStats.current }
    var bestStreak: Int { streakStats.best }

    var canSubmit: Bool {
        !isComplete
            && guessesUsed < Self.maxGuesses
            && !Puzzle.normalized(guessText).isEmpty
    }

    var revealLevel: Int {
        if isComplete { return Self.maxRevealLevel }
        return min(incorrectGuessCount, Self.maxRevealLevel)
    }

    var suggestions: [String] {
        guard let puzzle, !isComplete else { return [] }
        return wordListService.suggestions(
            matching: guessText,
            additional: puzzle.allAnswers,
            limit: 6
        )
    }

    private var incorrectGuessCount: Int {
        guard let puzzle else { return guesses.count }
        return guesses.filter { !puzzle.matches($0) }.count
    }

    init(
        puzzle: Puzzle? = nil,
        puzzleService: any PuzzleServing = PuzzleService.make(),
        progressStore: any PuzzleProgressStoring = UserDefaultsPuzzleProgressStore(),
        wordListService: any WordListServing = LocalWordListService(),
        streakStore: any StreakStoring = UserDefaultsStreakStore()
    ) {
        self.presetPuzzle = puzzle
        self.puzzleService = puzzleService
        self.progressStore = progressStore
        self.wordListService = wordListService
        self.streakStore = streakStore
        self.streakStats = streakStore.load()
        self.isLoading = (puzzle == nil)

        if let puzzle {
            self.puzzle = puzzle
        }
    }

    func load() async {
        if let presetPuzzle {
            puzzle = presetPuzzle
            errorMessage = nil
            isLoading = false
            restoreProgress(for: presetPuzzle)
            return
        }

        if let puzzle, Calendar.current.isDateInToday(puzzle.date), errorMessage == nil {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let todayPuzzle = try await puzzleService.fetchToday() else {
                puzzle = nil
                return
            }

            puzzle = todayPuzzle
            restoreProgress(for: todayPuzzle)
        } catch {
            puzzle = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func retry() async {
        puzzle = nil
        errorMessage = nil
        await load()
    }

    func applySuggestion(_ suggestion: String) {
        guessText = suggestion
    }

    func submitGuess() {
        guard canSubmit, let puzzle else { return }

        let guess = guessText.trimmingCharacters(in: .whitespacesAndNewlines)
        guesses.append(guess)
        guessText = ""

        if puzzle.matches(guess) {
            outcome = .solved
        } else if guesses.count >= Self.maxGuesses {
            outcome = .failed
        }

        persist()

        if isComplete, Calendar.current.isDateInToday(puzzle.date) {
            streakStats = streakStore.recordCompletion(outcome: outcome, on: puzzle.date)
        }
    }

    private func restoreProgress(for puzzle: Puzzle) {
        if let saved = progressStore.progress(for: puzzle.id) {
            guesses = saved.guesses
            outcome = saved.outcome
        } else {
            guesses = []
            outcome = .inProgress
        }
        guessText = ""

        if outcome != .inProgress, Calendar.current.isDateInToday(puzzle.date) {
            streakStats = streakStore.recordCompletion(outcome: outcome, on: puzzle.date)
        } else {
            streakStats = streakStore.load()
        }
    }

    private func persist() {
        guard let puzzle else { return }
        progressStore.save(
            PuzzleProgress(puzzleID: puzzle.id, guesses: guesses, outcome: outcome)
        )
    }
}
