import Foundation

@MainActor
protocol PuzzleProgressStoring {
    func progress(for puzzleID: String) -> PuzzleProgress?
    func save(_ progress: PuzzleProgress)
}

@MainActor
final class UserDefaultsPuzzleProgressStore: PuzzleProgressStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "puzzleProgress.v1") {
        self.defaults = defaults
        self.key = key
    }

    func progress(for puzzleID: String) -> PuzzleProgress? {
        allProgress()[puzzleID]
    }

    func save(_ progress: PuzzleProgress) {
        var stored = allProgress()
        stored[progress.puzzleID] = progress
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: key)
        }
    }

    private func allProgress() -> [String: PuzzleProgress] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: PuzzleProgress].self, from: data)) ?? [:]
    }
}

@MainActor
final class InMemoryPuzzleProgressStore: PuzzleProgressStoring {
    private var storage: [String: PuzzleProgress] = [:]

    func progress(for puzzleID: String) -> PuzzleProgress? {
        storage[puzzleID]
    }

    func save(_ progress: PuzzleProgress) {
        storage[progress.puzzleID] = progress
    }
}
