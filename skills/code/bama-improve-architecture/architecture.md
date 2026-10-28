# Architecture for apps that grow

The template starts with one target. Move to this shape when the app gets a
CLI, an engine (media, sync, parsing), or a second contributor.

## Contents

- Targets and dependency direction
- Edits as pure operations
- Split state by update rate
- Seams with two adapters
- Engines report counters, not exceptions
- Safe saves
- Errors
- File size norms
- Gotchas

## Targets and dependency direction

```text
App target (AppKit: windows, view controllers, menus) -> engine targets -> <App>Core
```

Never the reverse. `<App>Core` knows nothing about AppKit, UIKit,
AVFoundation, or Metal. When it grows, split the package, not the app
target:

```swift
// <App>Core/Package.swift
.target(name: "AppCore"),                                  // values, rules, math
.target(name: "AppStore", dependencies: ["AppCore"]),      // Core Data, sync
.target(name: "AppEngine", dependencies: ["AppCore"]),     // media, rendering, heavy work
.testTarget(name: "AppCoreTests", dependencies: ["AppCore"]),
```

The app target in `project.yml` depends on the products it needs. The
compiler then keeps UI types out of the core by force, and a UIKit app can
share the same products. The app target stays thin: view controllers that
read the store and call core functions.

## Edits as pure operations

Every change to the user's document is an operation applied to a value.
One entry point serves the UI, Undo, the CLI, and tests.

```swift
public enum EditOp: Codable, Sendable { case rename(id: ID, to: String), move(id: ID, to: Int) }

public extension Document {
    func apply(_ ops: [EditOp]) throws -> Document   // all or nothing, returns a new value
}

@discardableResult func perform(_ ops: [EditOp], named name: String) -> Bool {
    do {
        let next = try doc.apply(ops)
        guard next != doc else { return false }
        pushUndo(name); doc = next; scheduleSave(); return true
    } catch { errorMessage = error.localizedDescription; return false }
}
```

## Split state by update rate

A value that changes many times a second (a playhead, a meter, a timer)
lives in its own small object. Only the views that show it listen to it.
Posting it through the page's view controller, or a notification every
view hears, redraws the whole page.

```swift
@MainActor final class PlayheadClock {
    var frame = 0 { didSet { onChange?(frame) } }
    var onChange: ((Int) -> Void)?
}

final class PlayheadLabel: NSTextField {
    func observe(_ clock: PlayheadClock) {
        font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        clock.onChange = { [weak self] frame in self?.stringValue = "\(frame)" }
    }
}
```

Engines own their real-time state. The UI reads snapshots at the rate a
person can see: 15 Hz for meters, 1 Hz for device lists.

## Seams with two adapters

Add a protocol only where you swap behavior: network, clock, file system,
an external service. Give it a production adapter and a test adapter on
day one.

```swift
public protocol Transport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
struct URLSessionTransport: Transport { ... }
struct RecordedTransport: Transport { ... }    // tests: replays saved responses
```

## Engines report counters, not exceptions

Real-time paths never throw. They count what went wrong and expose a
snapshot.

```swift
public struct WriterStats: Sendable { var appended = 0, stalls = 0, dropped = 0, fallbacks = 0 }
public func snapshot() -> WriterStats { lock.withLock { stats } }
```

The self-test prints the counters. A non-zero `dropped` fails it.

## Safe saves

Write to a temp file, then rename (atomic). Keep a revision number; when the
file changed under you, reload and replay unsaved operations. Never
overwrite an output another feature points at: write a new version.

## Errors

A typed `enum` per module that conforms to `LocalizedError`. The UI shows
`errorMessage`. Media and real-time paths degrade (drop a preview frame,
fall back to the CPU) and count it.

## File size norms

Library files mostly 100 to 450 lines. A file over 600 lines is a check-in
signal. View models over 1,000 lines are the first refactor targets. Test
hooks live in a test target or behind a launch flag, not in app files.

## Gotchas

- Synthesized `Codable` can change the bytes of old files when you add a
  property (it writes `"items": []`). Keep a test that loads and re-saves
  an old file byte for byte.
- `model.child?.field = f(model.child)` on a class with property observers
  can crash with an exclusivity violation. Read into a `let` first.
- A menu action named like an AppKit setter (`setAppearance:`) crashes.
  Name actions `applyAppearance(_:)`.
- A huge function can crash the release optimizer. Split it.
- Two agents building one package at once break each other. New types
  land in new files that compile on their own; never add an empty target.
- Async job queues: give each job a generation number and claim it before
  starting, so a retry never runs a paid job twice.
