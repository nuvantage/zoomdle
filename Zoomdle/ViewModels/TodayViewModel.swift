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
    private let statsStore: any GameStatsStoring
    private let presetPuzzle: Puzzle?

    var puzzle: Puzzle?
    var guessText = ""
    var guesses: [String] = []
    var outcome: PuzzleProgress.Outcome = .inProgress
    var isLoading: Bool
    var errorMessage: String?
    var streakStats = StreakStats()

    private(set) var isAnimatingFinalReveal = false
    private(set) var submitPulse = 0
    private(set) var successPulse = 0
    private(set) var errorPulse = 0
    private(set) var duplicatePulse = 0
    private(set) var missPulse = 0
    private(set) var dismissKeyboardPulse = 0

    var guessesUsed: Int { guesses.count }
    var isComplete: Bool { outcome != .inProgress }
    var showsResults: Bool { isComplete && !isAnimatingFinalReveal }
    var currentStreak: Int { streakStats.current }
    var bestStreak: Int { streakStats.best }

    var currentGuessNumber: Int {
        min(guessesUsed + 1, Self.maxGuesses)
    }

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
        streakStore: any StreakStoring = UserDefaultsStreakStore(),
        statsStore: any GameStatsStoring = UserDefaultsGameStatsStore()
    ) {
        self.presetPuzzle = puzzle
        self.puzzleService = puzzleService
        self.progressStore = progressStore
        self.wordListService = wordListService
        self.streakStore = streakStore
        self.statsStore = statsStore
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
        if isDuplicate(guess) {
            duplicatePulse += 1
            missPulse += 1
            return
        }

        submitPulse += 1
        dismissKeyboardPulse += 1
        guesses.append(guess)
        guessText = ""

        if puzzle.matches(guess) {
            successPulse += 1
            outcome = .solved
            isAnimatingFinalReveal = true
        } else {
            errorPulse += 1
            missPulse += 1
            if guesses.count >= Self.maxGuesses {
                outcome = .failed
                isAnimatingFinalReveal = true
            }
        }

        persist()
        recordStreakIfNeeded(for: puzzle)
        recordStatsIfNeeded(for: puzzle)
    }

    func endFinalReveal() {
        isAnimatingFinalReveal = false
    }

    func resetToday() {
        guard let puzzle else { return }
        statsStore.retract(puzzleID: puzzle.id)
        progressStore.delete(puzzleID: puzzle.id)
        if shouldRecordStreak(for: puzzle) {
            streakStats = streakStore.clearCompletion(on: puzzle.date)
        }
        restoreProgress(for: puzzle)
    }

    private func isDuplicate(_ guess: String) -> Bool {
        let normalized = Puzzle.normalized(guess)
        return guesses.contains { Puzzle.normalized($0) == normalized }
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
        isAnimatingFinalReveal = false
        statsStore.backfill(from: Array(progressStore.allProgress().values))

        if shouldRecordStreak(for: puzzle), outcome != .inProgress {
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

    private func recordStreakIfNeeded(for puzzle: Puzzle) {
        guard isComplete, shouldRecordStreak(for: puzzle) else { return }
        streakStats = streakStore.recordCompletion(outcome: outcome, on: puzzle.date)
    }

    private func recordStatsIfNeeded(for puzzle: Puzzle) {
        guard isComplete else { return }
        statsStore.record(puzzleID: puzzle.id, outcome: outcome, guessesUsed: guesses.count)
    }

    /// Archive uses a preset puzzle, so even a calendar-today replay cannot change streaks.
    private func shouldRecordStreak(for puzzle: Puzzle) -> Bool {
        presetPuzzle == nil && Calendar.current.isDateInToday(puzzle.date)
    }
}
