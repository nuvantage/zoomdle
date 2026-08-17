import SwiftUI

struct ZoomRevealView: View {
    let imageName: String
    var imageURL: URL? = nil
    let revealLevel: Int
    let puzzleID: String

    private let maxRevealLevel = 5
    private let maxZoom: CGFloat = 6

    init(imageName: String, imageURL: URL? = nil, revealLevel: Int, puzzleID: String) {
        self.imageName = imageName
        self.imageURL = imageURL
        self.revealLevel = revealLevel
        self.puzzleID = puzzleID
    }

    init(puzzle: Puzzle, revealLevel: Int) {
        self.init(
            imageName: puzzle.imageName,
            imageURL: puzzle.imageURL,
            revealLevel: revealLevel,
            puzzleID: puzzle.id
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let side = max(min(proxy.size.width, proxy.size.height), 1)
            let transform = ZoomRevealTransform(
                revealLevel: revealLevel,
                puzzleID: puzzleID,
                size: side,
                maxRevealLevel: maxRevealLevel,
                maxZoom: maxZoom
            )

            PuzzleAssetImage(imageName: imageName, imageURL: imageURL, contentMode: .fill)
                .frame(width: side, height: side)
                .scaleEffect(transform.scale)
                .offset(transform.offset)
                .frame(width: side, height: side)
                .clipped()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .animation(.smooth(duration: 0.55), value: revealLevel)
    }
}

private struct ZoomRevealTransform {
    let scale: CGFloat
    let offset: CGSize

    init(
        revealLevel: Int,
        puzzleID: String,
        size: CGFloat,
        maxRevealLevel: Int,
        maxZoom: CGFloat
    ) {
        let clampedMaxLevel = max(maxRevealLevel, 1)
        let clampedMaxZoom = max(maxZoom, 1)
        let level = min(max(revealLevel, 0), clampedMaxLevel)
        let progress = CGFloat(level) / CGFloat(clampedMaxLevel)
        let minVisibleFraction = 1 / clampedMaxZoom
        let visibleFraction = max(minVisibleFraction + (1 - minVisibleFraction) * progress, 0.01)
        let scale = 1 / visibleFraction
        let crop = Self.cropCenter(puzzleID: puzzleID, inset: minVisibleFraction / 2)

        let origin = CGPoint(
            x: min(max(crop.x - visibleFraction / 2, 0), 1 - visibleFraction),
            y: min(max(crop.y - visibleFraction / 2, 0), 1 - visibleFraction)
        )
        let visibleCenter = CGPoint(
            x: origin.x + visibleFraction / 2,
            y: origin.y + visibleFraction / 2
        )

        self.scale = scale
        self.offset = CGSize(
            width: -(visibleCenter.x - 0.5) * size * scale,
            height: -(visibleCenter.y - 0.5) * size * scale
        )
    }

    private static func cropCenter(puzzleID: String, inset: CGFloat) -> CGPoint {
        let safeInset = min(max(inset, 0), 0.49)
        let hash = stableHash(puzzleID)
        let unitX = CGFloat(hash & 0xFFFF) / 65_535
        let unitY = CGFloat((hash >> 16) & 0xFFFF) / 65_535
        let span = 1 - 2 * safeInset
        return CGPoint(
            x: safeInset + unitX * span,
            y: safeInset + unitY * span
        )
    }

    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return hash
    }
}

#Preview {
    ZoomRevealPreview()
}

private struct ZoomRevealPreview: View {
    @State private var revealLevel = 0
    @State private var puzzleID = "2026-08-17"
    @State private var imageName = "puzzle-eiffel-tower"

    private let samples: [(id: String, imageName: String, answer: String)] = [
        ("2026-08-17", "puzzle-eiffel-tower", "Eiffel Tower"),
        ("2026-08-16", "puzzle-golden-retriever", "Golden Retriever"),
        ("2026-08-15", "puzzle-grand-piano", "Piano"),
        ("2026-08-14", "puzzle-pepperoni-pizza", "Pizza"),
        ("2026-08-13", "puzzle-saturn", "Saturn")
    ]

    var body: some View {
        VStack(spacing: 16) {
            ZoomRevealView(
                imageName: imageName,
                revealLevel: revealLevel,
                puzzleID: puzzleID
            )
            .background(Color.black.opacity(0.05))

            Stepper("Reveal level: \(revealLevel)", value: $revealLevel, in: 0...5)

            Picker("Puzzle", selection: $puzzleID) {
                ForEach(samples, id: \.id) { sample in
                    Text(sample.answer).tag(sample.id)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: puzzleID) { _, newID in
                imageName = samples.first { $0.id == newID }?.imageName ?? imageName
                revealLevel = 0
            }
        }
        .padding()
    }
}
