import SwiftUI

struct PuzzlePlayView: View {
    @Bindable var viewModel: TodayViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                AppLoadingView(message: "Loading puzzle…")
            } else if let errorMessage = viewModel.errorMessage {
                AppUnavailableView(
                    title: "Couldn't Load Puzzle",
                    systemImage: "exclamationmark.triangle",
                    message: errorMessage,
                    retry: {
                        Task { await viewModel.retry() }
                    }
                )
            } else if let puzzle = viewModel.puzzle {
                puzzleContent(puzzle)
            } else {
                AppUnavailableView(
                    title: "No Puzzle Today",
                    systemImage: "sun.max",
                    message: "Check back tomorrow for a new Zoomdle."
                )
            }
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func puzzleContent(_ puzzle: Puzzle) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isComplete {
                    ResultsView(
                        puzzle: puzzle,
                        outcome: viewModel.outcome,
                        guessesUsed: viewModel.guessesUsed,
                        currentStreak: viewModel.currentStreak,
                        bestStreak: viewModel.bestStreak
                    )
                } else {
                    ZoomRevealView(puzzle: puzzle, revealLevel: viewModel.revealLevel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(puzzle.category.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    guessMeter(for: puzzle)

                    GuessInputView(
                        text: $viewModel.guessText,
                        suggestions: viewModel.suggestions,
                        isSubmitEnabled: viewModel.canSubmit,
                        onSelectSuggestion: viewModel.applySuggestion,
                        onSubmit: viewModel.submitGuess
                    )
                }

                if !viewModel.guesses.isEmpty {
                    guessHistory(for: puzzle)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func guessMeter(for puzzle: Puzzle) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<TodayViewModel.maxGuesses, id: \.self) { index in
                Capsule()
                    .fill(pipColor(at: index, puzzle: puzzle))
                    .frame(height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Guess \(viewModel.guessesUsed) of \(TodayViewModel.maxGuesses)")
    }

    private func guessHistory(for puzzle: Puzzle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Guesses")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(viewModel.guesses.enumerated()), id: \.offset) { _, guess in
                HStack {
                    Text(guess)
                    Spacer()
                    Image(systemName: puzzle.matches(guess) ? "checkmark" : "xmark")
                        .foregroundStyle(puzzle.matches(guess) ? .green : .secondary)
                }
                .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pipColor(at index: Int, puzzle: Puzzle) -> Color {
        guard index >= 0, index < viewModel.guesses.count else {
            return Color.secondary.opacity(0.2)
        }
        return puzzle.matches(viewModel.guesses[index]) ? .green : .secondary.opacity(0.55)
    }
}
