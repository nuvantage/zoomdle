import SwiftUI

struct GuessInputView: View {
    @Binding var text: String
    let suggestions: [String]
    let isSubmitEnabled: Bool
    let missPulse: Int
    let dismissKeyboardPulse: Int
    let onSelectSuggestion: (String) -> Void
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool
    @State private var shakeOffset: CGFloat = 0
    @State private var flashMiss = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Enter a guess", text: $text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .offset(x: shakeOffset)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(flashMiss ? Color.red.opacity(0.85) : Color.clear, lineWidth: 2)
                }
                .onSubmit(submitIfEnabled)

            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                            Button(suggestion) {
                                onSelectSuggestion(suggestion)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Button("Submit Guess", action: submitIfEnabled)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isSubmitEnabled)
        }
        .task(id: missPulse) {
            guard missPulse > 0 else { return }
            await playMissFeedback()
        }
        .onChange(of: dismissKeyboardPulse) { _, _ in
            isFocused = false
        }
    }

    private func submitIfEnabled() {
        guard isSubmitEnabled else { return }
        onSubmit()
    }

    @MainActor
    private func playMissFeedback() async {
        flashMiss = true
        withAnimation(.linear(duration: 0.05).repeatCount(6, autoreverses: true)) {
            shakeOffset = 8
        }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.easeOut(duration: 0.12)) {
            shakeOffset = 0
            flashMiss = false
        }
    }
}
