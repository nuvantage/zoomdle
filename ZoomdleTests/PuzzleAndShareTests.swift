import UIKit
import XCTest
@testable import Zoomdle

final class PuzzleAndShareTests: XCTestCase {
    func testPuzzleMatchesIsCaseInsensitive() {
        let puzzle = Puzzle(
            id: "2026-08-17",
            date: Puzzle.date(fromJSON: "2026-08-17") ?? Date(),
            imageName: "puzzle-eiffel-tower",
            answer: "Eiffel Tower",
            acceptableAnswers: ["eiffel"],
            category: "Landmarks"
        )

        XCTAssertTrue(puzzle.matches("eiffel tower"))
        XCTAssertTrue(puzzle.matches("EIFFEL TOWER"))
        XCTAssertTrue(puzzle.matches("Eiffel"))
        XCTAssertFalse(puzzle.matches("pizza"))
    }

    func testShareResultGridForThreeOfSixWin() {
        XCTAssertEqual(
            ShareResult.grid(guessesUsed: 3, didSolve: true),
            "🟥🟥🟩⬜⬜⬜"
        )
    }

    func testEveryPuzzleCatalogImageLoadsForZoomReveal() async throws {
        let puzzles = try await LocalPuzzleService().fetchAll()
        XCTAssertEqual(puzzles.count, 60)

        for puzzle in puzzles {
            XCTAssertNotNil(
                UIImage(named: puzzle.imageName),
                "ZoomRevealView would fall back to the placeholder without catalog asset \(puzzle.imageName) (\(puzzle.id))"
            )
        }

        XCTAssertNotNil(UIImage(named: "LaunchLogo"), "Unplayed archive tiles require LaunchLogo")
    }

    func testLegalURLsAreHTTPSFromInfoPlist() {
        XCTAssertEqual(ZoomdleLegal.privacyURL?.absoluteString, "https://github.com/nuvantage/zoomdle/blob/gh-pages/PrivacyPolicy.md")
        XCTAssertEqual(ZoomdleLegal.termsURL?.absoluteString, "https://github.com/nuvantage/zoomdle/blob/gh-pages/Terms.md")
        XCTAssertEqual(ZoomdleLegal.supportURL?.absoluteString, "https://github.com/nuvantage/zoomdle/blob/gh-pages/Support.md")
    }
}
