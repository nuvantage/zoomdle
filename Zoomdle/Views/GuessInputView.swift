import SwiftUI

struct GuessInputView: View {
    @Binding var text: String
    let suggestions: [String]
    let isSubmitEnabled: Bool
    let onSelectSuggestion: (String) -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Enter a guess", text: $text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(onSubmit)

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

            Button("Submit Guess", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isSubmitEnabled)
        }
    }
}
