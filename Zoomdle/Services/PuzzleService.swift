import Foundation

protocol PuzzleServing: Sendable {
    func fetchAll() async throws -> [Puzzle]
    func fetchPuzzle(for date: Date) async throws -> Puzzle?
    func fetchPuzzle(id: String) async throws -> Puzzle?
}

extension PuzzleServing {
    func fetchToday() async throws -> Puzzle? {
        if let exact = try await fetchPuzzle(for: Date()) {
            return exact
        }

        let startOfToday = Calendar.current.startOfDay(for: Date())
        return try await fetchAll().first {
            Calendar.current.startOfDay(for: $0.date) <= startOfToday
        }
    }
}

enum PuzzleServiceError: LocalizedError {
    case fileNotFound
    case unreadable(Error)
    case decodingFailed(Error)
    case remoteUnavailable
    case emptyPayload

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Puzzle data couldn't be found. Please try again."
        case .unreadable:
            return "The puzzle file couldn't be read. Please try again."
        case .decodingFailed:
            return "The puzzle data looks invalid. Please try again."
        case .remoteUnavailable:
            return "Couldn't reach the puzzle server. Please try again."
        case .emptyPayload:
            return "The puzzle list was empty. Please try again."
        }
    }
}

/// Loads puzzles from bundled `puzzles.json`. Used as the instant source of
/// truth when disk cache is empty.
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
            let puzzles = try Puzzle.makeListDecoder().decode([Puzzle].self, from: data)
            return puzzles.sorted { $0.date > $1.date }
        } catch let error as DecodingError {
            throw PuzzleServiceError.decodingFailed(error)
        } catch let error as PuzzleServiceError {
            throw error
        } catch {
            throw PuzzleServiceError.unreadable(error)
        }
    }
}

/// Serves puzzles from disk cache, then the app bundle, and refreshes
/// `https://cdn.zoomdle.app/puzzles.json` in the background. Today and Archive
/// never wait on the CDN.
///
/// Expected JSON shape — an array of puzzles:
/// ```
/// [
///   {
///     "id": "2026-08-17",
///     "date": "2026-08-17",
///     "imageName": "puzzle-eiffel-tower",
///     "imageURL": "https://cdn.zoomdle.app/images/eiffel.jpg",
///     "answer": "Eiffel Tower",
///     "acceptableAnswers": ["eiffel"],
///     "category": "Landmarks"
///   }
/// ]
/// ```
/// `date` is `yyyy-MM-dd`. `imageURL` is optional; `imageName` is the asset catalog fallback.
actor RemotePuzzleService: PuzzleServing {
    static let defaultRemoteURL = URL(string: "https://cdn.zoomdle.app/puzzles.json")!

    private let remoteURL: URL
    private let session: URLSession
    private let cacheURL: URL
    private let fallback: any PuzzleServing
    private var cachedPuzzles: [Puzzle]?
    private var didScheduleRefresh = false

    init(
        remoteURL: URL = RemotePuzzleService.defaultRemoteURL,
        fallback: any PuzzleServing = LocalPuzzleService(),
        session: URLSession? = nil,
        cacheURL: URL = RemotePuzzleService.defaultCacheURL()
    ) {
        self.remoteURL = remoteURL
        self.fallback = fallback
        self.cacheURL = cacheURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 2
            configuration.timeoutIntervalForResource = 2
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchAll() async throws -> [Puzzle] {
        if cachedPuzzles == nil {
            if let disk = loadDiskCache() {
                cachedPuzzles = disk
            } else {
                cachedPuzzles = try await fallback.fetchAll()
            }
        }

        scheduleBackgroundRefresh()
        guard let puzzles = cachedPuzzles, !puzzles.isEmpty else {
            throw PuzzleServiceError.emptyPayload
        }
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

    private func scheduleBackgroundRefresh() {
        guard !didScheduleRefresh else { return }
        didScheduleRefresh = true
        Task { await self.refreshFromRemote() }
    }

    private func refreshFromRemote() async {
        do {
            let puzzles = try await fetchRemote()
            cachedPuzzles = puzzles
        } catch {
            return
        }
    }

    private func fetchRemote() async throws -> [Puzzle] {
        let data: Data
        do {
            let (received, response) = try await session.data(from: remoteURL)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw PuzzleServiceError.remoteUnavailable
            }
            data = received
        } catch let error as PuzzleServiceError {
            throw error
        } catch {
            throw PuzzleServiceError.remoteUnavailable
        }

        let puzzles: [Puzzle]
        do {
            puzzles = try Puzzle.makeListDecoder().decode([Puzzle].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            throw PuzzleServiceError.decodingFailed(error)
        }

        guard !puzzles.isEmpty else {
            throw PuzzleServiceError.emptyPayload
        }

        writeDiskCache(data)
        return puzzles
    }

    private func loadDiskCache() -> [Puzzle]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let puzzles = (try? Puzzle.makeListDecoder().decode([Puzzle].self, from: data))?
            .sorted { $0.date > $1.date }
        guard let puzzles, !puzzles.isEmpty else { return nil }
        return puzzles
    }

    private func writeDiskCache(_ data: Data) {
        do {
            try FileManager.default.createDirectory(
                at: cacheURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            return
        }
    }

    static func defaultCacheURL() -> URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return folder
            .appendingPathComponent("Zoomdle", isDirectory: true)
            .appendingPathComponent("puzzles.json")
    }
}

enum PuzzleService {
    static func make() -> any PuzzleServing {
        RemotePuzzleService(fallback: LocalPuzzleService())
    }
}
