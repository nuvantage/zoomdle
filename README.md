# Zoomdle

A Wordle-like daily game: guess the photo as it zooms from a tight crop to the full image. Six guesses. iOS 17+.

**Version 1.0 (build 1)** · Bundle ID `com.zoomdle.Zoomdle`

## Run in Xcode

1. Open `Zoomdle.xcodeproj` in Xcode 15 or later.
2. Select the **Zoomdle** scheme and an iOS 17+ simulator or device.
3. Signing: **Target → Signing & Capabilities → Automatically manage signing**, then choose your Apple Developer team. Keep the bundle ID `com.zoomdle.Zoomdle`.
4. Press Run.

Unit tests: **Product → Test** (or `Cmd+U`). They cover case-insensitive `Puzzle.matches` and a 3/6 share grid.

## TestFlight

Archive with **Product → Archive**, then distribute from Organizer to TestFlight.

| Setting | Value |
| --- | --- |
| Display name | Zoomdle |
| Bundle ID | `com.zoomdle.Zoomdle` |
| Version | 1.0 |
| Build | 1 |
| Icon | 1024×1024 App Store icon, no alpha |
| Encryption | Info.plist sets `ITSAppUsesNonExemptEncryption` to false |

App Store Connect also needs the same **Privacy Policy**, **Terms**, and **Support** URLs that are in Info.plist:

- Privacy: https://nuvantage.github.io/zoomdle/privacy/
- Terms: https://nuvantage.github.io/zoomdle/terms/
- Support: https://nuvantage.github.io/zoomdle/support/

Those pages are the HTML in `docs/`, served from the `gh-pages` branch. Source markdown: `PrivacyPolicy.md`, `Terms.md`, `Support.md`.

## Puzzles

Bundled catalog: `Zoomdle/Resources/puzzles.json` (2026-08-06 through 2026-10-04). Each day has `id`, `date` (`yyyy-MM-dd`), `imageName` (asset catalog), optional `imageURL`, `answer`, `acceptableAnswers`, and `category`. Matching images live in `Zoomdle/Assets.xcassets/puzzle-*.imageset`.

`PuzzleService.make()` serves disk cache, then the bundle, immediately. It refreshes `https://cdn.zoomdle.app/puzzles.json` in the background (2s timeout) and never blocks Today or Archive on a dead CDN. `fetchToday()` uses today’s date when present, otherwise the most recent puzzle dated on or before today.

The guess dictionary is `Zoomdle/Resources/words.json`. Rebuild with `python scripts/build_words_json.py`.

## Debug testing tools

In **Debug** builds only, Today → gear → **Testing** has **Reset Today** (replay the current puzzle) and **Reset Subscription** (clear Zoomdle Plus on this device). Release builds do not show that section.

Zoomdle Plus is a StoreKit 2 subscription (`com.zoomdle.Zoomdle.plus.monthly`). Simulator uses `Zoomdle.storekit` (selected on the Zoomdle scheme). Archive stays locked until a purchase or restore succeeds.

## Known stubs

- **CDN:** The placeholder host is still `https://cdn.zoomdle.app/puzzles.json`. A 404 or timeout does not delay play.
