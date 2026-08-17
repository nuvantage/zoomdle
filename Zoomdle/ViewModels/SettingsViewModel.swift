import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let progressStore: any PuzzleProgressStoring
    private let streakStore: any StreakStoring
    private let statsStore: any GameStatsStoring
    private let onResetToday: () -> Void

    var gameStats = GameStats()
    var streakStats = StreakStats()

    init(
        progressStore: any PuzzleProgressStoring = UserDefaultsPuzzleProgressStore(),
        streakStore: any StreakStoring = UserDefaultsStreakStore(),
        statsStore: any GameStatsStoring = UserDefaultsGameStatsStore(),
        onResetToday: @escaping () -> Void = {}
    ) {
        self.progressStore = progressStore
        self.streakStore = streakStore
        self.statsStore = statsStore
        self.onResetToday = onResetToday
        reload()
    }

    func reload() {
        gameStats = statsStore.backfill(from: Array(progressStore.allProgress().values))
        streakStats = streakStore.load()
    }

    func resetToday() {
        onResetToday()
        reload()
    }
}
