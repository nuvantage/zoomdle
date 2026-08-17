import Foundation
import Observation

@MainActor
@Observable
final class SubscriptionStore {
    private let defaults: UserDefaults
    private let key: String
    private let persists: Bool

    var isSubscribed: Bool {
        didSet {
            guard persists, oldValue != isSubscribed else { return }
            defaults.set(isSubscribed, forKey: key)
        }
    }

    init(
        defaults: UserDefaults = .standard,
        key: String = "isSubscribed",
        isSubscribed: Bool? = nil,
        persists: Bool = true
    ) {
        self.defaults = defaults
        self.key = key
        self.persists = persists
        self.isSubscribed = isSubscribed ?? (persists ? defaults.bool(forKey: key) : false)
    }

    func unlock() {
        isSubscribed = true
    }
}
