import Foundation

struct Puzzle: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let date: Date
    /// Asset catalog name used when `imageURL` is missing or the download fails.
    let imageName: String
    /// Optional CDN photo. Absent in bundled `puzzles.json`.
    var imageURL: URL? = nil
    let answer: String
    let acceptableAnswers: [String]
    let category: String
}

extension Puzzle {
    var allAnswers: [String] {
        [answer] + acceptableAnswers
    }

    func matches(_ guess: String) -> Bool {
        let normalizedGuess = Self.normalized(guess)
        guard !normalizedGuess.isEmpty else { return false }
        return allAnswers.contains { Self.normalized($0) == normalizedGuess }
    }

    static func normalized(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    static func date(fromJSON string: String) -> Date? {
        let parts = string.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    static func dayString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    /// Puzzle #1 is 2026-08-06, making 2026-08-17 Zoomdle #12.
    static let seriesStartDay = "2026-08-06"

    var number: Int {
        guard
            let start = Self.date(fromJSON: Self.seriesStartDay),
            let days = Calendar.current.dateComponents(
                [.day],
                from: start,
                to: Calendar.current.startOfDay(for: date)
            ).day
        else {
            return 1
        }
        return max(days + 1, 1)
    }

    static func makeListDecoder() -> JSONDecoder {
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
