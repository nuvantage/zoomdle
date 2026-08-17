import Foundation

protocol WordListServing: Sendable {
    func suggestions(matching query: String, additional extraWords: [String], limit: Int) -> [String]
}

struct LocalWordListService: WordListServing {
    private let words: [String]

    init(words: [String]) {
        self.words = words
    }

    init(bundle: Bundle = .main, fileName: String = "words") {
        if let url = bundle.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.words = decoded
        } else {
            self.words = Self.fallbackWords
        }
    }

    func suggestions(matching query: String, additional extraWords: [String] = [], limit: Int = 6) -> [String] {
        let needle = Puzzle.normalized(query)
        guard !needle.isEmpty else { return [] }

        var seen = Set<String>()
        var combined: [String] = []
        for word in extraWords + words {
            let key = Puzzle.normalized(word)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            combined.append(word)
        }

        let prefixMatches = combined.filter { Puzzle.normalized($0).hasPrefix(needle) }
        let containsMatches = combined.filter { value in
            let normalized = Puzzle.normalized(value)
            return normalized.contains(needle) && !normalized.hasPrefix(needle)
        }

        return Array((prefixMatches + containsMatches).prefix(limit))
    }

    private static let fallbackWords = [
        "Eiffel Tower", "Piano", "Pizza", "Saturn", "Golden Retriever"
    ]
}
