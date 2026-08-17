import Foundation

protocol PuzzleServing: Sendable {
    func fetchAll() async throws -> [Puzzle]
    func fetchPuzzle(for date: Date) async throws -> Puzzle?
    func fetchPuzzle(id: String) async throws -> Puzzle?
}

extension PuzzleServing {
    func fetchToday() async throws -> Puzzle? {
        try await fetchPuzzle(for: Date())
    }
}

enum PuzzleServiceError: LocalizedError {
    case fileNotFound
    case unreadable(Error)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Puzzle data couldn't be found. Please try again."
        case .unreadable:
            return "The puzzle file couldn't be read. Please try again."
        case .decodingFailed:
            return "The puzzle data looks invalid. Please try again."
        }
    }
}

/// Loads puzzles from bundled `puzzles.json`.
/// Callers should depend on `PuzzleServing` so this can later be replaced
/// with a remote CDN/backend implementation without changing call sites.
actor LocalPuzzleService: PuzzleServing {
    private let fileName: String
    private let fileURL: URL?
    private var cachedPuzzles: [Puzzle]?

    init(fileName: String = "puzzles") {
        self.fileName = fileName
        self.fileURL = nil
    }

    init(fileURL: URL) {
        self.fileName = "puzzles"
        self.fileURL = fileURL
    }

    func fetchAll() async throws -> [Puzzle] {
        if let cachedPuzzles {
            return cachedPuzzles
        }

        let puzzles = try loadPuzzles()
        cachedPuzzles = puzzles
        return puzzles
    }

    func fetchPuzzle(for date: Date) async throws -> Puzzle? {
        let puzzles = try await fetchAll()
        return puzzles.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func fetchPuzzle(id: String) async throws -> Puzzle? {
        let puzzles = try await fetchAll()
        return puzzles.first { $0.id == id }
    }

    private func loadPuzzles() throws -> [Puzzle] {
        guard let url = fileURL ?? Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw PuzzleServiceError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            let puzzles = try Self.makeDecoder().decode([Puzzle].self, from: data)
            return puzzles.sorted { $0.date > $1.date }
        } catch let error as DecodingError {
            throw PuzzleServiceError.decodingFailed(error)
        } catch let error as PuzzleServiceError {
            throw error
        } catch {
            throw PuzzleServiceError.unreadable(error)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Puzzle.date(fromJSON: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected date string in yyyy-MM-dd format, got \(string)."
                )
            }
            return date
        }
        return decoder
    }
}

enum PuzzleService {
    static func make() -> any PuzzleServing {
        LocalPuzzleService()
    }
}
