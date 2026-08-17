import SwiftUI

struct ResultsView: View {
    let puzzle: Puzzle
    let outcome: PuzzleProgress.Outcome
    let guessesUsed: Int
    let currentStreak: Int
    let bestStreak: Int

    private var didSolve: Bool { outcome == .solved }

    private var shareText: String {
        ShareResult.text(
            puzzleNumber: puzzle.number,
            guessesUsed: guessesUsed,
            didSolve: didSolve
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            PuzzleAssetImage(puzzle: puzzle, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement()
                .accessibilityLabel("Fully revealed puzzle image")

            VStack(spacing: 6) {
                Image(systemName: didSolve ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(didSolve ? Color.green : Color.red)

                Text(didSolve ? "You got it!" : "Out of guesses")
                    .font(.title2.bold())

                Text(puzzle.answer)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text(ShareResult.grid(guessesUsed: guessesUsed, didSolve: didSolve))
                    .font(.title2)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("Zoomdle #\(puzzle.number): \(ShareResult.score(guessesUsed: guessesUsed, didSolve: didSolve))")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                streakCard(title: "Current Streak", value: currentStreak)
                streakCard(title: "Best Streak", value: bestStreak)
            }

            ShareLink(item: shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func streakCard(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("Solved") {
    ResultsView(
        puzzle: Puzzle(
            id: "2026-08-17",
            date: Puzzle.date(fromJSON: "2026-08-17") ?? Date(),
            imageName: "puzzle-eiffel-tower",
            answer: "Eiffel Tower",
            acceptableAnswers: ["eiffel"],
            category: "Landmarks"
        ),
        outcome: .solved,
        guessesUsed: 3,
        currentStreak: 4,
        bestStreak: 9
    )
    .padding()
}

#Preview("Failed") {
    ResultsView(
        puzzle: Puzzle(
            id: "2026-08-17",
            date: Puzzle.date(fromJSON: "2026-08-17") ?? Date(),
            imageName: "puzzle-eiffel-tower",
            answer: "Eiffel Tower",
            acceptableAnswers: ["eiffel"],
            category: "Landmarks"
        ),
        outcome: .failed,
        guessesUsed: 6,
        currentStreak: 0,
        bestStreak: 9
    )
    .padding()
}
