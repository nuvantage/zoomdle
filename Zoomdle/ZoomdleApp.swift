import SwiftUI

@main
struct ZoomdleApp: App {
    @State private var subscriptionStore = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(subscriptionStore)
                .task {
                    await subscriptionStore.start()
                }
        }
    }
}
