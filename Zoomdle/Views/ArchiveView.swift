import SwiftUI

struct ArchiveView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @State private var viewModel: ArchiveViewModel
    @State private var path = NavigationPath()
    @State private var lockedPuzzle: Puzzle?

    init(viewModel: ArchiveViewModel = ArchiveViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading {
                    AppLoadingView(message: "Loading archive…")
                } else if let errorMessage = viewModel.errorMessage {
                    AppUnavailableView(
                        title: "Couldn't Load Archive",
                        systemImage: "exclamationmark.triangle",
                        message: errorMessage,
                        retry: {
                            Task { await viewModel.retry() }
                        }
                    )
                } else if viewModel.pastPuzzles.isEmpty {
                    AppUnavailableView(
                        title: "No Past Puzzles",
                        systemImage: "archivebox",
                        message: "Yesterday’s puzzle will appear here."
                    )
                } else {
                    archiveGrid
                }
            }
            .navigationTitle("Archive")
            .navigationDestination(for: Puzzle.self) { puzzle in
                ArchivePuzzleView(puzzle: puzzle)
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $lockedPuzzle) { puzzle in
            PaywallView {
                subscriptionStore.unlock()
                let puzzleToOpen = puzzle
                lockedPuzzle = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    path.append(puzzleToOpen)
                }
            }
        }
    }

    private var archiveGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.monthSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.title3.bold())
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(section.puzzles) { puzzle in
                                let unlocked = viewModel.isUnlocked(puzzle, isSubscribed: subscriptionStore.isSubscribed)
                                ArchiveThumbnailView(
                                    puzzle: puzzle,
                                    isLocked: !unlocked,
                                    isCompleted: viewModel.hasProgress(for: puzzle)
                                )
                                .onTapGesture {
                                    select(puzzle, isUnlocked: unlocked)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func select(_ puzzle: Puzzle, isUnlocked: Bool) {
        if isUnlocked {
            path.append(puzzle)
        } else {
            lockedPuzzle = puzzle
        }
    }
}

private struct ArchiveThumbnailView: View {
    let puzzle: Puzzle
    let isLocked: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                PuzzleAssetImage(imageName: puzzle.imageName, contentMode: .fill)
                    .blur(radius: isLocked ? 20 : 0)
                    .scaleEffect(isLocked ? 1.15 : 1)
                    .allowsHitTesting(false)

                if isLocked {
                    Color.black.opacity(0.4)
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                } else if isCompleted {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .padding(8)
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(puzzle.date, format: .dateTime.month(.abbreviated).day())
                .font(.headline)
            Text("#\(puzzle.number)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        let date = puzzle.date.formatted(.dateTime.month(.wide).day())
        if isLocked {
            return "Locked puzzle, \(date)"
        }
        if isCompleted {
            return "Completed puzzle, \(date)"
        }
        return "Puzzle \(date)"
    }
}

private struct ArchivePuzzleView: View {
    @State private var viewModel: TodayViewModel

    init(puzzle: Puzzle) {
        _viewModel = State(initialValue: TodayViewModel(puzzle: puzzle))
    }

    var body: some View {
        PuzzlePlayView(viewModel: viewModel)
            .navigationTitle(viewModel.puzzle?.date.formatted(.dateTime.month(.abbreviated).day()) ?? "Puzzle")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ArchiveView()
        .environment(SubscriptionStore(isSubscribed: false, persists: false))
}
