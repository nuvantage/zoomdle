import Foundation

@MainActor
protocol PuzzleProgressStoring {
    func progress(for puzzleID: String) -> PuzzleProgress?
    func save(_ progress: PuzzleProgress)
    func delete(puzzleID: String)
    func allProgress() -> [String: PuzzleProgress]
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
        write(stored)
    }

    func delete(puzzleID: String) {
        var stored = allProgress()
        stored.removeValue(forKey: puzzleID)
        write(stored)
    }

    func allProgress() -> [String: PuzzleProgress] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: PuzzleProgress].self, from: data)) ?? [:]
    }

    private func write(_ stored: [String: PuzzleProgress]) {
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: key)
        }
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

    func delete(puzzleID: String) {
        storage.removeValue(forKey: puzzleID)
    }

    func allProgress() -> [String: PuzzleProgress] {
        storage
    }
}
