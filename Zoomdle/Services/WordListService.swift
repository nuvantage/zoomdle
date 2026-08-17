import Foundation

protocol WordListServing: Sendable {
    func suggestions(matching query: String, additional extraWords: [String], limit: Int) -> [String]
}

struct LocalWordListService: WordListServing {
    private let entries: [WordEntry]

    private struct WordEntry: Sendable {
        let display: String
        let normalized: String
    }

    init(words: [String]) {
        self.entries = Self.uniqueEntries(from: words)
    }

    init(bundle: Bundle = .main, fileName: String = "words") {
        if let url = bundle.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.entries = Self.uniqueEntries(from: decoded)
        } else {
            self.entries = Self.uniqueEntries(from: Self.fallbackWords)
        }
    }

    func suggestions(matching query: String, additional extraWords: [String] = [], limit: Int = 6) -> [String] {
        let needle = Puzzle.normalized(query)
        guard !needle.isEmpty, limit > 0 else { return [] }

        let extraEntries = Self.uniqueEntries(from: extraWords)
        let extraKeys = Set(extraEntries.map(\.normalized))
        let dictionaryEntries = entries.filter { !extraKeys.contains($0.normalized) }
        let combined = extraEntries + dictionaryEntries

        let prefixMatches = combined
            .filter { $0.normalized.hasPrefix(needle) }
            .sorted { lhs, rhs in
                Self.rank(
                    lhs,
                    rhs,
                    needle: needle,
                    extraKeys: extraKeys
                )
            }

        let containsMatches = combined
            .filter { $0.normalized.contains(needle) && !$0.normalized.hasPrefix(needle) }
            .sorted { lhs, rhs in
                Self.rank(
                    lhs,
                    rhs,
                    needle: needle,
                    extraKeys: extraKeys
                )
            }

        return Array((prefixMatches + containsMatches).prefix(limit)).map(\.display)
    }

    private static func rank(
        _ lhs: WordEntry,
        _ rhs: WordEntry,
        needle: String,
        extraKeys: Set<String>
    ) -> Bool {
        let leftExact = lhs.normalized == needle
        let rightExact = rhs.normalized == needle
        if leftExact != rightExact { return leftExact }

        let leftExtra = extraKeys.contains(lhs.normalized)
        let rightExtra = extraKeys.contains(rhs.normalized)
        if leftExtra != rightExtra { return leftExtra && !rightExtra }

        if lhs.normalized.count != rhs.normalized.count {
            return lhs.normalized.count < rhs.normalized.count
        }

        return lhs.display.localizedCaseInsensitiveCompare(rhs.display) == .orderedAscending
    }

    private static func uniqueEntries(from words: [String]) -> [WordEntry] {
        var seen = Set<String>()
        var entries: [WordEntry] = []
        for word in words {
            let normalized = Puzzle.normalized(word)
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            entries.append(WordEntry(display: word.trimmingCharacters(in: .whitespacesAndNewlines), normalized: normalized))
        }
        return entries
    }

    private static let fallbackWords = [
        "Eiffel Tower", "Piano", "Pizza", "Saturn", "Golden Retriever"
    ]
}
