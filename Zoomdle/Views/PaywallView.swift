import SwiftUI

struct PaywallView: View {
    var onUnlock: () -> Void
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                Image(systemName: "archivebox.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)

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
                    Text("$4.99 / month")
                        .font(.title2.bold())
                    Text("Placeholder pricing — StoreKit coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                Spacer()

                Button("Unlock") {
                    onUnlock()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Restore Purchases") {}
                    .disabled(true)
                    .font(.subheadline)

                Button("Not Now") {
                    onDismiss?()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(24)
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
        }
    }

    private func paywallFeature(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            Text(text)
        }
    }
}

#Preview {
    PaywallView(onUnlock: {})
}
