# __APP_NAME__

A native macOS app in SwiftUI. It runs on this Mac only, with a local
SwiftData database and no server.

What the app is for: the Bear note "__APP_NAME__ brief". Terms and
decisions: `CONTEXT.md`. Check its glossary before naming anything in code
or docs.

## Layout

- `Sources/__APP_NAME__/` the app. `App.swift` has the window, menus, and the database location.
- `Sources/__APP_NAME__Kit/` rules and data logic with no SwiftUI. Tests in `Tests/__APP_NAME__KitTests/`.
- `Package.swift` a Swift package. There is no Xcode project.
- `build.sh` builds, signs, and installs `~/Applications/__APP_NAME__.app`.
- `Icon/AppIcon.icon` the app icon, an Icon Composer file (JSON plus SVG layers). `build.sh` compiles it with `tools/make_icon.sh`; `tools/icon_review.sh` renders every look into one PNG.
- `docs/agents/` how to use the issue tracker (OmniFocus and Bear). `docs/screens/` reference screenshots. `docs/FIXLOG.md` and `docs/architecture-review-<date>.md` when they exist.

## Build and check

- Build and install: `./build.sh`. Add `--open` to restart the app with the new build. The build shows warnings; fix them.
- Unit tests: `swift test --scratch-path ~/Library/Developer/__APP_NAME__/test-build`.
- Self-test (the app's real functions on a /tmp store): `tools/selftest.sh`. Exit 0 when every check passes. Add a check for every story with logic in `SelfTest.swift`.
- After every UI change, take snapshots with sample data and look at them: `tools/snap.sh`.
  It writes `/tmp/__APP_NAME__-shots/<page>-light.png` and `-dark.png` for every sidebar page, and `settings-<tab>-light.png` and `-dark.png` for every Settings tab, then quits. `APP_SNAPSHOT_PAGES=all,settings tools/snap.sh` limits the pages.
  For a panel, sheet, or popover, add a capture to `Snapshot.swift` like the Settings loop.
- Snapshots, seed data, and the self-test refuse to run without `APP_STORE` in /tmp.
- Never test against the real database in `~/Library/Application Support/__APP_NAME__/`.
- Then check the grid: `tools/grid-lint.sh` and `swift tools/check-layout.swift /tmp/__APP_NAME__-shots/*-layout.json`. Both print PASS.
- A change is done when the build has no errors, the grid checks pass, and you looked at the light and dark snapshots.

## Design rules

- Use Apple's controls and system styles. Only the accent color is custom: `UI/Theme.swift` (`ThemeStore.defaultID`). People change it, and light or dark mode, in Settings > Appearance.
- Views use `.tint`, `Palette.accent`, `Palette.accentText` (accent-colored text), and `Palette.onAccent` (text on an accent fill). Never hard-code colors, radii, or durations in views.
- Compare accents: add `APP_ACCENT=<id>` to the snapshot command.
- Spacing comes from `Space` in `UI/Grid.swift`, on a 4 pt grid. Mark custom pages and cards with `.gridArea` and `.gridProbe`.
- Windows open calm: `.noInitialFocus()` on every window and sheet (no focus ring or selected text on open), `.fitsContent()` on sheets and Settings tabs (no scroll bar with nothing to scroll). System scroll bars. Both in `UI/WindowBehavior.swift`.
- Settings: one tab per topic in `SettingsView.swift`, one grouped Form per tab. Add a case to `SettingsTab` for a new tab.
- Window chrome (title bar, toolbar, sidebar, menus, sheets) stays system. Buttons use system styles, like `.borderedProminent`.
- Colors: `.primary`, `.secondary`, `.tint`, and system colors. Never fixed grays or white for text.
- Every action has a menu bar item and a keyboard shortcut.
- `Label` for icon and text pairs. SF Symbols for icons.
- `ContentUnavailableView` for empty states.
- Liquid Glass belongs to floating controls only, never to content.

## Skills

The bama plugin has a skill for each step: `bama-mac-design` (design rules),
`bama-design-system` (accent and tokens), `bama-layout-grid`, `bama-ux-design`,
`bama-swift`, `bama-os-integrations`, `bama-performance`, `bama-build-and-verify`,
`bama-test-app`, `bama-app-icon`, `bama-user-stories`, and `bama-improve-loop`. Use them.

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
