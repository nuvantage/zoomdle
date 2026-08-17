import SwiftUI
import UIKit

struct AppLoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct AppUnavailableView: View {
    let title: String
    let systemImage: String
    let message: String
    var retryTitle: String = "Try Again"
    var retry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PuzzleAssetImage: View {
    let imageName: String
    var imageURL: URL? = nil
    var contentMode: ContentMode = .fill

    init(imageName: String, imageURL: URL? = nil, contentMode: ContentMode = .fill) {
        self.imageName = imageName
        self.imageURL = imageURL
        self.contentMode = contentMode
    }

    init(puzzle: Puzzle, contentMode: ContentMode = .fill) {
        self.init(imageName: puzzle.imageName, imageURL: puzzle.imageURL, contentMode: contentMode)
    }

    var body: some View {
        Group {
            if PuzzleAssetImage.exists(imageName) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: "photo")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }

    private static func exists(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        true
        #endif
    }
}
