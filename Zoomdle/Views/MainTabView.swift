import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            ArchiveView()
                .tabItem {
                    Label("Archive", systemImage: "archivebox.fill")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .environment(SubscriptionStore(isSubscribed: false, persists: false))
}
