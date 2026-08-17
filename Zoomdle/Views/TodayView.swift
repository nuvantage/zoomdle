import SwiftUI

struct TodayView: View {
    @State private var viewModel: TodayViewModel

    init(viewModel: TodayViewModel = TodayViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            PuzzlePlayView(viewModel: viewModel)
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView(
        viewModel: TodayViewModel(
            progressStore: InMemoryPuzzleProgressStore(),
            streakStore: InMemoryStreakStore()
        )
    )
}
