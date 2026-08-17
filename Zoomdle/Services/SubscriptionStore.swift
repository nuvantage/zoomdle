import Foundation
import Observation
import StoreKit

/// Single subscription flag used by Today and Archive.
/// `isSubscribed` comes only from StoreKit 2 entitlements for
/// `com.zoomdle.Zoomdle.plus.monthly`. There is no local UserDefaults unlock.
@MainActor
@Observable
final class SubscriptionStore {
    static let plusMonthlyProductID = "com.zoomdle.Zoomdle.plus.monthly"

    /// When false (SwiftUI previews), skip StoreKit.
    private let allowsStoreKit: Bool
    private var updatesTask: Task<Void, Never>?

    private(set) var isSubscribed: Bool
    private(set) var product: Product?
    private(set) var isBusy = false
    private(set) var isLoadingProduct = false
    var errorMessage: String?

    var displayPrice: String {
        if let product {
            return "\(product.displayPrice) / month"
        }
        return "—"
    }

    var priceFootnote: String {
        if isLoadingProduct {
            return "Fetching price from the App Store…"
        }
        if product == nil {
            return errorMessage ?? "Zoomdle Plus isn’t available. Archive stays locked until it can be purchased."
        }
        return "Auto-renews monthly. Cancel anytime in Apple ID settings."
    }

    var canPurchase: Bool {
        !isBusy && product != nil
    }

    init(isSubscribed: Bool? = nil, persists: Bool = true) {
        self.allowsStoreKit = persists
        self.isSubscribed = persists ? false : (isSubscribed ?? false)
    }

    func start() async {
        guard allowsStoreKit else { return }

        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    await self?.handle(transactionUpdate: result)
                }
            }
        }
        await refresh()
    }

    func purchase() async -> PurchaseOutcome {
        errorMessage = nil
        guard allowsStoreKit else {
            return .failed("Purchases aren’t available.")
        }
        guard let product else {
            let message = "Zoomdle Plus isn’t available yet. Archive stays locked."
            errorMessage = message
            return .failed(message)
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                guard let transaction = verified(verification) else {
                    let message = "Couldn’t verify the purchase."
                    errorMessage = message
                    return .failed(message)
                }
                await transaction.finish()
                #if DEBUG
                clearDebugSubscriptionOverride()
                #endif
                await refreshEntitlements()
                return isSubscribed
                    ? .subscribed
                    : .failed("Purchase finished, but Zoomdle Plus isn’t active yet.")
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Purchase couldn’t be completed.")
            }
        } catch {
            errorMessage = error.localizedDescription
            return .failed(error.localizedDescription)
        }
    }

    func restore() async -> RestoreOutcome {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        guard allowsStoreKit else {
            return .failed("Purchases aren’t available.")
        }

        #if DEBUG
        clearDebugSubscriptionOverride()
        #endif

        var syncError: String?
        do {
            try await AppStore.sync()
        } catch {
            syncError = error.localizedDescription
        }

        await refreshEntitlements()

        if isSubscribed {
            return .restored
        }
        if let syncError {
            errorMessage = syncError
            return .failed(syncError)
        }
        return .notFound
    }

    private func refresh() async {
        await loadProduct()
        await refreshEntitlements()
    }

    private func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [Self.plusMonthlyProductID])
            product = products.first { $0.id == Self.plusMonthlyProductID }
            if product == nil {
                errorMessage = "Zoomdle Plus isn’t available yet. Archive stays locked."
            } else {
                errorMessage = nil
            }
        } catch {
            product = nil
            errorMessage = error.localizedDescription
        }
    }

    private func refreshEntitlements() async {
        isSubscribed = await hasActivePlus()
    }

    private func hasActivePlus() async -> Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: Self.debugForceUnsubscribedKey) {
            return false
        }
        #endif
        for await result in Transaction.currentEntitlements {
            guard let transaction = verified(result) else { continue }
            guard transaction.productID == Self.plusMonthlyProductID else { continue }
            if let revocationDate = transaction.revocationDate, revocationDate <= Date() {
                continue
            }
            if let expirationDate = transaction.expirationDate, expirationDate <= Date() {
                continue
            }
            return true
        }
        return false
    }

    private func handle(transactionUpdate result: VerificationResult<Transaction>) async {
        guard let transaction = verified(result) else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func verified(_ result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }

    #if DEBUG
    private static let debugForceUnsubscribedKey = "zoomdle.debug.forceUnsubscribed"

    func resetSubscription() {
        UserDefaults.standard.set(true, forKey: Self.debugForceUnsubscribedKey)
        isSubscribed = false
    }

    private func clearDebugSubscriptionOverride() {
        UserDefaults.standard.set(false, forKey: Self.debugForceUnsubscribedKey)
    }
    #endif
}

enum PurchaseOutcome: Equatable {
    case subscribed
    case cancelled
    case pending
    case failed(String)
}

enum RestoreOutcome: Equatable {
    case restored
    case notFound
    case failed(String)
}
