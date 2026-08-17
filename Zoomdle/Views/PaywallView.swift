import SwiftUI

struct PaywallView: View {
    var onSubscribed: () -> Void
    var onDismiss: (() -> Void)?

    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var statusMessage: String?
    @State private var showStatus = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("Unlock the Archive")
                            .font(.title.bold())
                        Text("Play every past Zoomdle puzzle whenever you like.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        paywallFeature("Full access to every past puzzle")
                        paywallFeature("Play any day you’ve missed")
                        paywallFeature("New puzzles added daily")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(spacing: 4) {
                        Text("Zoomdle Plus")
                            .font(.headline)
                        Text(subscriptionStore.displayPrice)
                            .font(.title2.bold())
                        Text(subscriptionStore.priceFootnote)
                            .font(.caption)
                            .foregroundStyle(
                                subscriptionStore.product == nil && !subscriptionStore.isLoadingProduct
                                    ? Color.red
                                    : Color.secondary
                            )
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    Button {
                        Task { await purchase() }
                    } label: {
                        if subscriptionStore.isBusy {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Subscribe")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!subscriptionStore.canPurchase)

                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    .disabled(subscriptionStore.isBusy)
                    .font(.subheadline)

                    Button("Not Now") {
                        onDismiss?()
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    legalLinks
                }
                .padding(24)
            }
            .navigationTitle("Archive Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
            .task {
                await subscriptionStore.start()
            }
            .alert("Purchases", isPresented: $showStatus, presenting: statusMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var legalLinks: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let privacyURL = ZoomdleLegal.privacyURL {
                    Link("Privacy Policy", destination: privacyURL)
                }
                Text("·")
                    .foregroundStyle(.secondary)
                if let termsURL = ZoomdleLegal.termsURL {
                    Link("Terms of Use", destination: termsURL)
                }
            }
            if let supportURL = ZoomdleLegal.supportURL {
                Link("Support", destination: supportURL)
            }
        }
        .font(.caption)
    }

    private func paywallFeature(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            Text(text)
        }
    }

    private func purchase() async {
        let outcome = await subscriptionStore.purchase()
        switch outcome {
        case .subscribed:
            onSubscribed()
        case .cancelled:
            break
        case .pending:
            present("Your purchase is pending approval. Archive will unlock once Apple confirms it.")
        case .failed(let message):
            present(message)
        }
    }

    private func restore() async {
        let outcome = await subscriptionStore.restore()
        switch outcome {
        case .restored:
            onSubscribed()
        case .notFound:
            present("No previous Zoomdle Plus subscription was found for this Apple ID.")
        case .failed(let message):
            present(message)
        }
    }

    private func present(_ message: String) {
        statusMessage = message
        showStatus = true
    }
}

#Preview {
    PaywallView(onSubscribed: {})
        .environment(SubscriptionStore(isSubscribed: false, persists: false))
}
