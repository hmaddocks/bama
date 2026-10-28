---
name: bama-new-app
description: Create a native app for Mac (AppKit), iPhone and iPad (UIKit), or both from a skeleton that builds, tests, and snapshots on day one (XcodeGen project, Core Data core package, build script, snapshot mode, self-test, git). Use when the user wants to start a new app or scaffold a project, or add iPhone and iPad to a Mac app.
argument-hint: "<AppName> <bundle-id> [parent-folder] [--platforms mac|ios|both]"
allowed-tools: Bash(*/new-app.sh *) Bash(*/add-ios.sh *) Bash(git *) Bash(./build.sh *) Bash(bin/test *) Bash(tools/*) Read Write Edit
---

# New app

The template is a skeleton, not a starter app: one empty window (and on
iOS, one empty screen), the menu bar, an empty Core Data model, and the
plumbing every feature needs. It
builds and runs as is, so the first build proves the toolchain before any
feature code. Everything a person sees comes from the first milestone's
tickets.

## What the skeleton is

Laid out like Cashflow: an AppKit target for the Mac, a UIKit target for
iPhone and iPad, or both, sharing a local Swift package for the logic, in
an Xcode project generated from `project.yml`.

```text
<AppName>/
  project.yml            XcodeGen: the macOS 26 and iOS 26 targets, both depend on <AppName>Core
  build.sh               xcodegen -> xcodebuild -> ~/Applications, or the simulator or a device with --ios
  bin/test               swift test for <AppName>Core, with a full Xcode pinned
  AGENTS.md              architecture, build, check, design, and writing rules (CLAUDE.md links to it)
  CONTEXT.md             glossary and decisions
  DESIGN.md              design tokens and when to use each
  docs/agents/           how to use the issue tracker: OmniFocus and Bear
  Icon/AppIcon.icon      the app icon: Icon Composer file, compiled by Xcode
  <AppName>/
    main.swift           NSApplicationMain, so MainMenu.xib wires the delegate
    AppDelegate.swift    @objc(AppDelegate): opens the store and the main window
    MainMenu.xib         the menu bar and the main window, nothing else
    MainWindowController.swift  the main window; undo goes to the store
    DesignTokens.swift   colours, fonts, and the Space scale
    Snapshot.swift       APP_SNAPSHOT mode: every registered page, light and dark
    SelfTest.swift       --selftest: PASS or FAIL per check, exit code
    SeedData.swift       APP_SEED=1 sample data for snapshots
  <AppName>iOS/          the iPhone and iPad app (--platforms ios or both)
    AppDelegate.swift    @main; UIKit needs no xib
    SceneDelegate.swift  opens the store and the window with one empty screen
    DesignTokens.swift   the same tokens as UIColor
    Snapshot.swift, SelfTest.swift, SeedData.swift  the same contracts as the Mac
  <AppName>Core/
    Package.swift        no AppKit or UIKit, macOS 26 and iOS 26
    Sources/<AppName>Core/Persistence/
      Store.swift        the Core Data stack; Debug uses <AppName>-dev.sqlite; APP_STORE overrides
      <AppName>Core.xcdatamodeld  the entities, empty to start
    Plugins/CoreDataModelPlugin  compiles the model for swift test
    Tests/<AppName>CoreTests     Swift Testing
  tools/
    snap.sh, selftest.sh          the Mac snapshots and self-test on a /tmp store
    snap-ios.sh, selftest-ios.sh  the same in the simulator
    grid-lint.sh         flags spacing numbers off the 4 pt scale
    omnifocus-setup.sh   ticket tags and status (bama-app-brief)
    make_icon.sh, icon_review.sh, icon_sheet.swift  check and review the icon
```

There is no sidebar, list, tab bar, Settings window, or sample data. Build
them from tickets with the recipes in `bama-swift` (appkit-recipes.md and
uikit-recipes.md).

## Steps

1. Check the toolchain. The skeleton needs a full Xcode (xcodebuild, momc,
   the Swift macros) and XcodeGen:

   ```bash
   xcodebuild -version        # Xcode 26 or later
   xcodegen --version         # brew install xcodegen
   sw_vers -productVersion    # 26.0 or later
   ```

   Check: all three print a version. `new-app.sh` stops with the fix when
   one is missing.

2. Pick the name (one UpperCamelCase word), bundle id (reverse DNS), and
   platforms: `mac`, `ios` (iPhone and iPad), or `both`. If a Bear note
   "<AppName> brief" exists, use its name and its `## Platforms` value.
   Without one, the platform is `mac`.

3. Run the script with the parent folder. It copies the skeleton, renames
   every `__APP_NAME__` file and folder, fills in the name, bundle id and
   Bear tag, keeps the targets for the platforms, fills the signing team
   from your Apple Development certificate, runs `git init`, and commits.
   It keeps files already there, such as the agent docs from
   `bama-app-brief`.

   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/new-app.sh" Tasks com.yourname.tasks ~/Developer --platforms both
   ```

   In a Dropbox or iCloud Drive folder the script can take minutes: run it
   in the background.

   Check: the folder has `project.yml` and one commit.

4. Build, install, and open it:

   ```bash
   cd ~/Developer/Tasks && ./build.sh --open    # the Mac app
   ./build.sh --ios                             # the iOS app in the iPhone 17 simulator
   ```

   Check: the Mac app shows one empty window titled with the app's name,
   and the App, File, Edit, View, Window, and Help menus. `--ios` prints
   `installed <AppName>iOS in the iPhone 17 simulator`.

5. Run the checks the skeleton ships with, then look at the snapshots
   (`bama-build-and-verify` skill):

   ```bash
   bin/test               # Core tests, PASS
   tools/selftest.sh      # SELFTEST PASS, exit 0
   tools/snap.sh          # /tmp/Tasks-shots/main-light.png and main-dark.png
   tools/grid-lint.sh     # PASS grid-lint
   tools/selftest-ios.sh  # with an iOS target: SELFTEST PASS
   tools/snap-ios.sh      # with an iOS target: /tmp/Tasks-shots-ios/main-iphone-light.png and more
   ```

   Check: every command for the app's platforms passes.

Features go through `bama-improve-loop`, one ticket at a time.

## Add iPhone and iPad to a Mac app

```bash
"${CLAUDE_SKILL_DIR}/scripts/add-ios.sh" ~/Developer/Tasks
```

It copies `<AppName>iOS/` and the iOS tools, appends the iOS target to
`project.yml`, and shares the icon with iOS. Move any seed data into
`<AppName>iOS/SeedData.swift`, run `./build.sh --ios`,
`tools/selftest-ios.sh` and `tools/snap-ios.sh`, then commit. It needs
`targets:` to be the last section of `project.yml`, as the skeleton has it.

## Signing

`build.sh` signs the installed copy with the first "Apple Development"
certificate in the keychain, or ad hoc without one. Permissions
(Accessibility, Screen Recording, camera) are stored per signature and
path. Ad hoc builds ask again after every rebuild. A free Apple ID makes a
certificate in Xcode > Settings > Accounts > Manage Certificates. Install
to the same path every time.

The iOS target signs automatically with the team in `project.yml`
(`DEVELOPMENT_TEAM`). Simulator builds need no signing.
`./build.sh --ios --device` installs on a connected iPhone or iPad: connect
it with a cable, unlock it, tap Trust, and turn on Developer Mode
(Settings > Privacy & Security). The first device build registers the
device. Without a certificate, `DEVELOPMENT_TEAM` is empty; add your team
id to use a device.

## A CLI for agents

To let Claude Code, Codex, or scripts read and change the app's data, call
the Skill tool with `bama-agent-cli`. The app binary becomes its own CLI and
sends each command to the running app, so the store keeps one writer and
the window updates live.

## When the build fails

`build.sh` prints the first errors and the path of the full log
(`~/Library/Developer/<AppName>/build.log`).

- `plugin for module 'TestingMacros' not found` or `momc` missing: the
  Command Line Tools are selected. `build.sh` and `bin/test` pin Xcode; set
  `DEVELOPER_DIR` if Xcode is not in `/Applications`.
- A new file is not compiled: files in `<AppName>/` are picked up when the
  project is generated. Touch `project.yml`, or run `xcodegen generate`.
- `Unknown class 'AppDelegate'` or an outlet that fails to connect: the
  `@objc(AppDelegate)` or `main.swift` was changed. See the comment in
  `AppDelegate.swift`.
- Concurrency or Core Data errors: call the Skill tool with `bama-swift`.

Done when the first commit exists, `bin/test` and `tools/grid-lint.sh`
pass, and for each platform: the Mac app opens from `~/Applications` with
one empty window and its menu bar, and `tools/selftest.sh` and
`tools/snap.sh` pass; the iOS app launches in the simulator, and
`tools/selftest-ios.sh` and `tools/snap-ios.sh` pass.
