import SwiftUI

struct TodayView: View {
    @State private var viewModel: TodayViewModel
    @State private var showSettings = false

    init(viewModel: TodayViewModel = TodayViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            PuzzlePlayView(viewModel: viewModel)
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        highlightedGuessCount: viewModel.outcome == .solved ? viewModel.guessesUsed : nil,
                        viewModel: SettingsViewModel(onResetToday: viewModel.resetToday)
                    )
                }
        }
    }
}

#Preview {
    TodayView(
        viewModel: TodayViewModel(
            progressStore: InMemoryPuzzleProgressStore(),
            streakStore: InMemoryStreakStore(),
            statsStore: InMemoryGameStatsStore()
        )
    )
    .environment(SubscriptionStore(isSubscribed: false, persists: false))
}
