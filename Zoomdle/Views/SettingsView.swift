import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel
    #if DEBUG
    @State private var confirmResetToday = false
    @State private var confirmResetSubscription = false
    #endif
    @State private var restoreMessage: String?
    @State private var showRestoreResult = false

    private let highlightedGuessCount: Int?

    init(
        highlightedGuessCount: Int? = nil,
        viewModel: SettingsViewModel = SettingsViewModel()
    ) {
        self.highlightedGuessCount = highlightedGuessCount
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                statisticsSection
                guessDistributionSection
                purchasesSection
                legalSection
                #if DEBUG
                testingSection
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.reload()
            }
            #if DEBUG
            .alert("Reset Today?", isPresented: $confirmResetToday) {
                Button("Reset Today", role: .destructive, action: viewModel.resetToday)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears today’s puzzle so you can play it again. Stats and streak for this puzzle will be undone.")
            }
            .alert("Reset Subscription?", isPresented: $confirmResetSubscription) {
                Button("Reset Subscription", role: .destructive) {
                    subscriptionStore.resetSubscription()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This turns off Zoomdle Plus on this device so you can test the Archive paywall. Restore Purchases turns it back on if Apple still has an active subscription.")
            }
            #endif
            .alert("Restore Purchases", isPresented: $showRestoreResult, presenting: restoreMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var statisticsSection: some View {
        Section("Statistics") {
            HStack(spacing: 8) {
                statistic(value: "\(viewModel.gameStats.gamesPlayed)", title: "Played")
                statistic(value: "\(viewModel.gameStats.winPercent)", title: "Win %")
                statistic(value: "\(viewModel.streakStats.current)", title: "Current\nStreak")
                statistic(value: "\(viewModel.streakStats.best)", title: "Max\nStreak")
            }
            .padding(.vertical, 8)
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        }
    }

    private var guessDistributionSection: some View {
        Section("Guess Distribution") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(1...TodayViewModel.maxGuesses, id: \.self) { guessCount in
                    distributionRow(
                        guessCount: guessCount,
                        count: viewModel.gameStats.wins(forGuessCount: guessCount),
                        highlighted: highlightedGuessCount == guessCount
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var purchasesSection: some View {
        Section("Purchases") {
            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
            if subscriptionStore.isSubscribed {
                Text("Zoomdle Plus is active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            if let privacyURL = ZoomdleLegal.privacyURL {
                Link("Privacy Policy", destination: privacyURL)
            }
            if let termsURL = ZoomdleLegal.termsURL {
                Link("Terms of Use", destination: termsURL)
            }
            if let supportURL = ZoomdleLegal.supportURL {
                Link("Support", destination: supportURL)
            }
        }
    }

    #if DEBUG
    private var testingSection: some View {
        Section {
            Button("Reset Today", role: .destructive) {
                confirmResetToday = true
            }
            Button("Reset Subscription", role: .destructive) {
                confirmResetSubscription = true
            }
        } header: {
            Text("Testing")
        } footer: {
            Text("Debug only. Reset Today lets you replay the current puzzle. Reset Subscription clears Zoomdle Plus on this device until you restore or subscribe again.")
        }
    }
    #endif

    private func restorePurchases() async {
        let outcome = await subscriptionStore.restore()
        switch outcome {
        case .restored:
            restoreMessage = "Zoomdle Plus was restored on this device."
        case .notFound:
            restoreMessage = "No previous Zoomdle Plus subscription was found for this Apple ID."
        case .failed(let message):
            restoreMessage = message
        }
        showRestoreResult = true
    }

    private func statistic(value: String, title: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
    }

    private func distributionRow(guessCount: Int, count: Int, highlighted: Bool) -> some View {
        let maxCount = max(viewModel.gameStats.maxDistributionCount, 1)

        return HStack(spacing: 8) {
            Text("\(guessCount)")
                .font(.body.monospacedDigit())
                .frame(width: 16, alignment: .center)

            GeometryReader { proxy in
                let fraction = CGFloat(count) / CGFloat(maxCount)
                let width = max(count == 0 ? 28 : 32, proxy.size.width * fraction)

                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(highlighted ? Color.accentColor : Color.secondary.opacity(count == 0 ? 0.28 : 0.55))
                    Text("\(count)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                }
                .frame(width: min(width, proxy.size.width), height: 22)
            }
            .frame(height: 22)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(guessCount) guesses, \(count) wins\(highlighted ? ", today’s puzzle" : "")")
    }
}

#Preview {
    SettingsView(
        highlightedGuessCount: 3,
        viewModel: SettingsViewModel(
            progressStore: InMemoryPuzzleProgressStore(),
            streakStore: InMemoryStreakStore(stats: StreakStats(current: 4, best: 9)),
            statsStore: InMemoryGameStatsStore(
                stats: GameStats(
                    games: [
                        RecordedGame(puzzleID: "1", didWin: true, guessesUsed: 2),
                        RecordedGame(puzzleID: "2", didWin: true, guessesUsed: 3),
                        RecordedGame(puzzleID: "3", didWin: true, guessesUsed: 3),
                        RecordedGame(puzzleID: "4", didWin: false, guessesUsed: 6)
                    ]
                )
            )
        )
    )
    .environment(SubscriptionStore(isSubscribed: true, persists: false))
}
