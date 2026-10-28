---
name: bama-build-and-verify
description: Build an AppKit Mac app or a UIKit iPhone and iPad app from the command line, install it, and check light and dark snapshots of every page before calling a change done. Use after any UI code change, when a build fails, or when the user asks to run, screenshot, or check the app.
allowed-tools: Bash(./build.sh*) Bash(bin/test*) Bash(tools/*) Bash(*/Contents/MacOS/*) Bash(open *) Read
---

# Build and verify

A change is done when four things are true:

1. `./build.sh` finishes with no errors or warnings, and `bin/test` passes.
2. You looked at the light and dark snapshots of every page you touched.
3. The snapshots match what the ticket or reference screenshot asks for.
4. The grid lint passes (`bama-layout-grid` skill).

A change to the iOS target? Steps 1 and 2 have iOS commands: see
"iPhone and iPad" below. Steps 3 to 6 are the same.

App not made from the `bama-new-app` skeleton (a committed Xcode project, a
SwiftUI app, a menu bar utility, Swift 5)? Map the commands below with
[existing-app.md](existing-app.md) first.

Do not report a UI change as done from the code alone. AppKit code that
compiles can still lay out an empty pane, clip text, or be unreadable in
dark mode.

## 1. Build and test

```bash
./build.sh            # release build, installs ~/Applications/<AppName>.app
./build.sh --debug    # debug build (uses <AppName>-dev.sqlite)
./build.sh --open     # also restarts the app so the user sees the new build
bin/test              # the <AppName>Core tests
```

`build.sh` regenerates the Xcode project when `project.yml` changed, builds
with Xcode's toolchain, and prints the errors and warnings. The full log is
`~/Library/Developer/<AppName>/build.log`. Fix the first error first: later
errors often come from it. A new file that is not compiled needs the
project regenerated: touch `project.yml`, or run `xcodegen generate`.

Check: `build.sh` prints `installed` with no warnings above it, and
`bin/test` passes.

## 2. Snapshot

Run the installed app in snapshot mode with a test store. It opens, shows
every registered page in light and dark mode, saves one PNG per page and
mode, and quits.

```bash
tools/snap.sh
# SNAPSHOT /tmp/<AppName>-shots/main-light.png
# ...
# SNAPSHOT done /tmp/<AppName>-shots
```

`tools/snap.sh` deletes the old test store (with its `-wal` and `-shm`
files) and the saved window state first, then runs with sample data
(`APP_SEED=1`). `APP_SNAPSHOT_PAGES=main,settings-general` limits the pages.

Pages are registered in `AppDelegate.snapshotPages`. Every sidebar item,
sheet, panel, alert, and Settings tab a ticket adds gets a page, whose
`show` closure brings it up and returns the window to capture (for a sheet,
`window.attachedSheet`). A screen with no page is a screen nobody checks.

In every image, look for three bugs agents often miss: a focus ring or
selected text that nobody asked for, a scroll bar with nothing to scroll,
and an empty band under short content. The fixes are in `bama-mac-design`,
"Windows open calm".

To see scroll bars as people with a mouse see them, add
`-AppleShowScrollBars Always` after the binary path. It changes only this
run.

Always use `APP_STORE` with a path in `/tmp`. Snapshot mode and the
self-test refuse to run without it, before the real store is opened.

Check: one light and one dark PNG per page you touched, and no line ends
with `(not key ...)` or `(fallback ...)`.

### Seed data

Empty pages only show empty states. `<AppName>/SeedData.swift` fills an
empty test store when `APP_SEED=1` is set. Grow it with the app: 10 to 20
objects with long and short titles, dates in the past and future, every
status, and only what a person can create in the app.

### Screen Recording permission

Snapshots use `screencapture -l <window>`, which shows glass, sidebars, and
materials exactly as on screen. It needs Screen Recording permission for the
app that runs the command (Terminal, Ghostty, or Claude). If a snapshot line
ends with `(fallback: ...)`, the permission is missing and sidebars and glass
render blank. Ask the user to allow it in System Settings > Privacy &
Security > Screen & System Audio Recording, then restart the terminal.

### Inactive windows

Grey traffic lights mean the window was not key when it was captured:
sidebar text, selection, and toggles look dimmer than in use. Snapshot mode
activates the app and waits for it before the first capture, and marks any
capture of an inactive window with `(not key ...)`. A snapshot of an
inactive window does not count as reviewed. Run the snapshots again while
nobody else uses the screen, and do not "fix" dim text you only see there.

### Missing snapshots

If every snapshot fails, or `screencapture` says "could not create image
from window", the display is probably asleep: an unattended Mac turns it
off. Snapshot mode wakes the display itself. For captures from outside the
app (like `window-shot.sh`), run `caffeinate -u -t 2` first.

If some pages print "no window" while others work, another app hid yours
during the run, or the page's `show` closure returned nil. Computer use
hides apps it does not control, and so does Hide Others. Run it again, and
avoid using computer use in another session at the same time.

### iPhone and iPad

```bash
./build.sh --ios              # build, install and launch in the iPhone 17 simulator
SIM_DEVICE="iPad Pro 11-inch (M5)" ./build.sh --ios
./build.sh --ios --device     # the connected iPhone or iPad
tools/snap-ios.sh
# SNAPSHOT /tmp/<AppName>-shots-ios/main-iphone-light.png
# ...
# SNAPSHOT /tmp/<AppName>-shots-ios/main-ipad-dark.png
```

`tools/snap-ios.sh` builds first, then runs snapshot mode on the iPhone 17
in portrait and the iPad Pro 11-inch in landscape, each on a fresh /tmp
store with seed data. The simulator shares the Mac's `/tmp`, and
`SIMCTL_CHILD_` passes the `APP_` variables to the app. Pages are
registered in `SceneDelegate.snapshotPages`.

- `simctl launch` exits 0 whatever the app does. The scripts read its
  output (`SNAPSHOT done`, `SELFTEST PASS`) instead.
- iPadOS 26 does not let an app rotate itself in the simulator. Landscape
  iPad images lay the root view out at the landscape size and draw it off
  screen. A page with a sheet open is drawn in portrait instead, and its
  line ends with `(portrait: a sheet is open)`: that is expected.
- Simulator captures need no Screen Recording permission, and nothing
  else on the screen can hide them.
- Without Simulator.app the simulator runs headless. `build.sh` opens its
  window only when it is installed.

Check: four PNGs per page you touched (iPhone and iPad, light and dark),
and the last line of each device is `SNAPSHOT done`.

## 3. Check the grid

```bash
tools/grid-lint.sh
```

It prints `PASS grid-lint`. On a FAIL, call the Skill tool with
`bama-layout-grid`: it has the rules and a table of fixes.

## 4. Look

Open every PNG with the Read tool and check, in this order:

- Nothing is blank, clipped, or overlapping. Text fits. Sidebars show their items.
- Dark mode is readable. No fixed white or black surfaces.
- The page matches the ticket or the reference screenshot (layout, labels, order).
- The `bama-mac-design` rules hold (on iOS, `bama-ios-design`): glass only
  on controls, one accent, SF Symbols, system text styles, empty states
  that invite the first action.

Describe what you see in one or two sentences per page in your report, and
name the PNG paths so the user can open them.

## 5. Interaction checks

Snapshots show state, not behavior. Run `tools/selftest.sh`, or
`tools/selftest-ios.sh` for the iOS target (exit 0 when every check passes), and add a check for each new action whose model or
storage behavior a unit test cannot reach. The `bama-test-app` skill covers
unit tests, the self-test, key events, the menu check from outside, and a
debug bridge.

### Debug output and private screens

A GUI app started with its output going to a file buffers `print`, and the
lines are lost when the process is killed. Write debug lines to stderr
(`FileHandle.standardError.write`) behind an environment flag.

Do not take full-screen captures to check your app: they show the user's
other windows. Capture your own window, or register a snapshot page that
renders the state you want to see (prefilled text, an open sheet).

## 6. Commit

When the build is clean and the snapshots look right, commit with a message
that says what the user can now do: "Add tasks from the quick-add panel",
not "Update views".

Done when the four conditions at the top hold and the change is committed.
