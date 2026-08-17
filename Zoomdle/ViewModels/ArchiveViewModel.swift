import Foundation
import Observation

@MainActor
@Observable
final class ArchiveViewModel {
    private let puzzleService: any PuzzleServing
    private let progressStore: any PuzzleProgressStoring

    var puzzles: [Puzzle] = []
    var isLoading = true
    var errorMessage: String?

    init(
        puzzleService: any PuzzleServing = PuzzleService.make(),
        progressStore: any PuzzleProgressStoring = UserDefaultsPuzzleProgressStore()
    ) {
        self.puzzleService = puzzleService
        self.progressStore = progressStore
    }

    var pastPuzzles: [Puzzle] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return puzzles
            .filter { Calendar.current.startOfDay(for: $0.date) < startOfToday }
            .sorted { $0.date > $1.date }
    }

    var monthSections: [ArchiveMonthSection] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: pastPuzzles) { puzzle in
            formatter.string(from: puzzle.date)
        }

        return grouped
            .map { ArchiveMonthSection(title: $0.key, puzzles: $0.value.sorted { $0.date > $1.date }) }
            .sorted { ($0.puzzles.first?.date ?? .distantPast) > ($1.puzzles.first?.date ?? .distantPast) }
    }

    func load() async {
        if !puzzles.isEmpty, errorMessage == nil { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            puzzles = try await puzzleService.fetchAll()
        } catch {
            puzzles = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func retry() async {
        puzzles = []
        errorMessage = nil
        await load()
    }

    func hasProgress(for puzzle: Puzzle) -> Bool {
        progressStore.progress(for: puzzle.id) != nil
    }

    func isUnlocked(_ puzzle: Puzzle, isSubscribed: Bool) -> Bool {
        isSubscribed || hasProgress(for: puzzle)
    }
}

struct ArchiveMonthSection: Identifiable {
    let title: String
    let puzzles: [Puzzle]
    var id: String { title }
}
