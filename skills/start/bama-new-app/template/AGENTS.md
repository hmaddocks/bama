# __APP_NAME__

A native app in Swift: AppKit on the Mac, and UIKit on iPhone and iPad
when `project.yml` has the `__APP_NAME__iOS` target. Each device keeps a
local Core Data store. There is no server.

What the app is for: the Bear note "__APP_NAME__ brief". Terms and
decisions: `CONTEXT.md`. Check its glossary before naming anything in code
or docs.

## Architecture

- **AppKit and UIKit**, not SwiftUI. SwiftUI only for a contained piece
  that needs it (Swift Charts in an `NSHostingView` or
  `UIHostingController`), with the reason in `CONTEXT.md`.
- **`__APP_NAME__Core`**, a local Swift package: models, storage, and logic.
  No AppKit or UIKit types may appear in it. Tests live there.
- **Core Data**. Entities are in
  `__APP_NAME__Core/Sources/__APP_NAME__Core/Persistence/__APP_NAME__Core.xcdatamodeld`.
  After a change that is not a lightweight migration, add a model version.
- `__APP_NAME__/MainMenu.xib` holds the menu bar and the main window only.
  View controllers and layout are in Swift.
- `main.swift` calls `NSApplicationMain`, and `AppDelegate` is
  `@objc(AppDelegate)`. The comment in `AppDelegate.swift` says why; keep both.
- **Platform defaults** for UI behaviour: what AppKit and UIKit do out of the box
  and what the Human Interface Guidelines describe. When a ticket departs
  from the default, ask before building it: name the default and what the
  departure costs.

## Layout

- `__APP_NAME__/` the app target: `AppDelegate.swift`, `MainWindowController.swift`,
  `MainMenu.xib`, `DesignTokens.swift`.
- `__APP_NAME__Core/` the package: `Sources/`, `Tests/`, and the plugin that
  compiles the Core Data model for `swift test`.
- `project.yml` the Xcode project's source. `__APP_NAME__.xcodeproj` is
  generated from it and not committed.
- `Icon/AppIcon.icon` the app icon, an Icon Composer file. Xcode compiles
  it. `tools/icon_review.sh` renders every look into one PNG.
- `DESIGN.md` the design tokens and when to use each.
- `docs/agents/` how to use the issue tracker (OmniFocus and Bear).
  `docs/screens/` reference screenshots. `docs/FIXLOG.md` and
  `docs/architecture-review-<date>.md` when they exist.

## Build and check

- Build and install: `./build.sh`. It regenerates the Xcode project when
  `project.yml` changed, builds with Xcode's toolchain, and installs
  `~/Applications/__APP_NAME__.app`. `--open` restarts the app with the new
  build; `--debug` builds Debug, which uses `__APP_NAME__-dev.sqlite`. Fix
  every warning it prints.
- Core tests: `bin/test` (pins a full Xcode; `bin/test --filter Store`).
  Logic tests use plain values or protocol-based fakes. In-memory Core Data
  only for store-level tests.
- Self-test (the app's real functions on a /tmp store): `tools/selftest.sh`.
  Exit 0 when every check passes. Add a check for every ticket whose model
  or storage behavior a unit test cannot reach.
- Snapshots: `tools/snap.sh` writes `/tmp/__APP_NAME__-shots/<page>-light.png`
  and `-dark.png` for every registered page, then quits.
  `APP_SNAPSHOT_PAGES=main tools/snap.sh` limits the pages. Look at them.
- Snapshots, seed data, and the self-test refuse to run without `APP_STORE`
  in /tmp. Never test against the real store in
  `~/Library/Application Support/__APP_NAME__/`.
- Spacing: `tools/grid-lint.sh` prints PASS.
- A change is done when the build has no errors or warnings, `bin/test`
  and the grid lint pass, and you looked at the light and dark snapshots.

## Design rules

- AppKit controls and system styles. Window chrome (title bar, toolbar,
  sidebar, menus, sheets) stays system.
- Colours and fonts come from `DesignTokens.swift` or system colours
  (`.labelColor`, `.secondaryLabelColor`, `.controlAccentColor`). Never a
  fixed grey or white for text. `DESIGN.md` says which token to use when.
- Spacing comes from `Space` in `DesignTokens.swift`, on a 4 pt grid.
- Every action has a menu item, and a keyboard shortcut where it is used
  often. Menu items validate (`NSMenuItemValidation`).
- Edits go through the store's view context, so Edit > Undo works.
- SF Symbols for icons.

<!-- ios-begin -->
## iPhone and iPad

- `__APP_NAME__iOS/` the UIKit target: `AppDelegate.swift` (`@main`, no
  xib), `SceneDelegate.swift` (opens the store, sets the root view
  controller, lists the snapshot pages), `DesignTokens.swift` (the same
  tokens as `UIColor`). It shares `__APP_NAME__Core` with the Mac app and
  nothing else.
- Build, install and launch in the iPhone 17 simulator: `./build.sh --ios`.
  On a connected device: `./build.sh --ios --device`.
- Self-test: `tools/selftest-ios.sh`. Snapshots: `tools/snap-ios.sh` writes
  `/tmp/__APP_NAME__-shots-ios/<page>-<iphone|ipad>-<light|dark>.png`,
  the iPhone in portrait and the iPad in landscape. Look at them.
- A screen is designed for touch, not copied from the Mac: the
  `bama-ios-design` skill. Navigation is a tab bar on iPhone and a sidebar
  on iPad, with the same pages.
- A change to the iOS app is done when `./build.sh --ios` has no warnings,
  `tools/selftest-ios.sh` passes, and you looked at the snapshots on both
  devices.
<!-- ios-end -->

## Git

- Commit after each working change, with a message that says what the user can now do.

## Writing

Write plainly. Short sentences, no rhetorical framing. State findings, do
not editorialise about them.

Do not create documents that have not been asked for. If another document
would help, say so and wait. Specs live in Bear, never in this repo.

## Agent skills

### Issue tracker

OmniFocus project "__APP_NAME__ App", with specs in Bear notes tagged
#__BEAR_TAG__. See `docs/agents/issue-tracker.md`.

### Triage labels

The five triage tags, under the OmniFocus tag group "__APP_NAME__ triage".
See `docs/agents/triage-labels.md`.

### Domain docs

Single-context. Glossary and decisions in `CONTEXT.md`. See
`docs/agents/domain.md`.
