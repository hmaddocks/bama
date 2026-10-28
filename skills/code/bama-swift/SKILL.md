---
name: bama-swift
description: Swift 6, AppKit, and Core Data code rules for Mac apps, including concurrency, the core package, menus and undo, hosting a SwiftUI piece, and fixes for common compiler errors. Use when writing, reviewing, or debugging Swift code in a Mac app, or on concurrency, Sendable, Core Data, or xib errors.
---

# Swift, AppKit, and Core Data

The code is right when it builds with zero warnings in Swift 6 language
mode, `bin/test` passes, and the app does what the ticket says. For how it
should look, call the Skill tool with `bama-mac-design`. For copyable AppKit
code (split view, source list, table view, sheets, undo), read
[appkit-recipes.md](appkit-recipes.md).

## Where code goes

| Code | Put it in |
| --- | --- |
| Models, storage, rules, parsing, calculations | `<App>Core`, with tests in `<App>Core/Tests` |
| View controllers, windows, menus, views | The app target, `<App>/` |
| A value both need (a formatter's rules, a validation) | `<App>Core`, as a pure function or type |

`<App>Core` never imports AppKit or UIKit. If a model needs a colour or an
image, store a name or a token id and resolve it in the app target.

Put logic in pure types in `<App>Core` and test them with plain values or
protocol-based fakes. Use the in-memory store (`Store(url: nil)`) only for
store-level tests. A test that opens a persistent store to test a pure
function is wrong.

## Concurrency

AppKit classes (`NSViewController`, `NSWindowController`, `NSView`) are
main-actor already. Mark your own UI-facing classes `@MainActor`.

| Work | Put it in |
| --- | --- |
| UI state, view controllers, the store's view context | Main actor |
| CPU-heavy pure work (parsing, image work, diffing) | A `nonisolated` function marked `@concurrent` |
| Core Data work off the main thread | `container.performBackgroundTask { context in ... }` |
| Shared mutable state used off the main thread | An `actor` |
| A C callback (event tap, Carbon hotkey, CoreAudio listener) | A `nonisolated` static func that hops back with `Task { @MainActor in ... }` |

- Data that crosses actors is `Sendable`: structs and enums of `Sendable`
  values, or `final class` with only `let` properties. Pass an
  `NSManagedObjectID`, never an `NSManagedObject`.
- `MainActor.assumeIsolated { }` inside a callback you know runs on the main
  thread (a main run loop `Timer`, a main queue notification).
- `Task { }` inherits the actor. `Task.detached` only when it must not.
- Fix a concurrency error at its type, not with `@unchecked Sendable` or
  `nonisolated(unsafe)`. Those two are a last resort, with a comment why.
- **Runtime trap the compiler misses.** A closure created inside a
  `@MainActor` type and passed to an API without a `@Sendable` closure
  parameter (`DispatchSource.setEventHandler`, `DispatchWorkItem`,
  `addPeriodicTimeObserver`, CoreAudio listener blocks) inherits the main
  actor. When it runs on a background queue, Swift 6 crashes the app. Write
  it as `{ @Sendable in ... }`, and run every background path once after
  any concurrency change.

## Core Data

- Entities live in `<App>Core.xcdatamodeld`. Write an `NSManagedObject`
  subclass per entity in `<App>Core` (codegen "Manual/None"), with a
  `@nonobjc class func fetchRequest()` and `@NSManaged` properties.
- Every new attribute is optional or has a default, so the store migrates
  automatically. A change that is not a lightweight migration (a type
  change, a split entity) gets a new model version.
- Give every entity a `uuid` attribute. Look objects up by it, not by
  `objectID`, which changes on the first save.
- Views read and edit through `store.viewContext` on the main actor. Save
  with `store.save()` after each user action, so a crash loses nothing.
- Undo comes from the view context's undo manager, which the main window
  returns for Edit > Undo. Group a multi-step action with
  `undoManager.beginUndoGrouping()` and `endUndoGrouping()`, and name it
  with `setActionName("Delete Counter")`.
- Watch changes with an `NSFetchedResultsController` for a list, or
  `NSManagedObjectContext.didChangeObjectsNotification` for a summary.
- The store lives in `~/Library/Application Support/<App>/`. Debug builds
  use `<App>-dev.sqlite`. `APP_STORE` overrides both, so tests, snapshots
  and the self-test never touch real data.

## The app's structure

- `MainMenu.xib` holds the menu bar and the main window only. Build view
  controllers and layout in Swift, with Auto Layout and `NSStackView`.
- Keep `main.swift` calling `NSApplicationMain`, and `@objc(AppDelegate)`
  on the app delegate. With `@main`, the xib's outlets fail at runtime;
  without `@objc(...)`, the nib loader cannot find the class and silently
  uses `NSObject`. The same goes for any class a xib names.
- Windows in a xib are `restorable="NO"`, and keep their frame with
  `setFrameAutosaveName`. A restorable window replays the frame from an
  old run after launch, which undoes any size you set in code.
- One window controller per window. The main window's content is usually
  an `NSSplitViewController`: a source-list sidebar and a content pane.
  Recipe in [appkit-recipes.md](appkit-recipes.md).
- Register a snapshot page in `AppDelegate.snapshotPages` for every sidebar
  item, sheet, panel and Settings tab you add.

## Menu commands

- Every action is a menu item. Put it in `MainMenu.xib` or build it in
  code, with the action sent to the first responder (target `nil`), and
  implement it on the view controller that owns the selection.
- Validate with `NSMenuItemValidation.validateMenuItem(_:)`: return false
  when there is nothing to act on, and set the title when it depends on
  the selection ("Delete 3 Counters"). Never ship an item that stays
  enabled and does nothing.
- A menu shortcut also fires while a text field has focus. Never use
  Delete, Command-Delete, arrows, or Return as menu shortcuts. Handle them
  in the table view (`keyDown(with:)`, or `NSResponder.deleteBackward(_:)`
  on the view controller).

## Hosting a SwiftUI piece

SwiftUI is for a contained piece that AppKit has no good answer for, such
as a chart drawn with Swift Charts. Before you add one, write a decision in
`CONTEXT.md` that says what it is and why AppKit does not cover it.

- Host it in an `NSHostingView` (or `NSHostingController`) inside an AppKit
  view controller. Set `sizingOptions` to match how it is laid out.
- Pass it plain values (a struct of chart points), not Core Data objects or
  the store. It holds no state of its own; the view controller rebuilds it
  when the data changes.
- Keep it in its own file, named after what it shows (`TrendChart.swift`).

## Names Swift already uses

Never name a type `Task`, `View`, `Color`, `Image`, `Text`, `Section`,
`Label`, `Menu`, `Group`, or `Settings`. `Task` breaks every
`Task { }`. Use `Todo`, `TaskItem`, `NoteSection`.

## Compiler errors

| Error | Fix |
| --- | --- |
| A new file is not compiled | Files are picked up when the project is generated. Touch `project.yml` or run `xcodegen generate` |
| `plugin for module 'TestingMacros' not found` | The Command Line Tools are selected. Use `bin/test` and `./build.sh`, which pin Xcode |
| `Could not find the compiled <App>Core.momd` | The model was loaded from `Bundle.main`. Load it from `Bundle.module`, as `Store` does |
| `Unknown class 'X' in Interface Builder file` | Add `@objc(X)` to the class |
| `Main actor-isolated ... from a nonisolated context` | Make the caller main-actor, or `await` the call |
| `Sending 'x' risks causing data races` | Make the type `Sendable`, or keep it on one actor |
| `ambiguous use of 'Task'` | A type in your code is named `Task`; rename it |

Fix the first error first. Later errors often come from it.

## Swift 6 errors

Moving an existing Swift 5 app? Read
[../../ship/bama-build-and-verify/existing-app.md](../../ship/bama-build-and-verify/existing-app.md)
first: expect several build rounds, then hunt the runtime trap above.

| Error | Fix |
| --- | --- |
| Static `let` of a non-Sendable type (formatter, `NSFont`, `CFString`) | `@MainActor` on the enclosing type, a computed `var`, or a commented `nonisolated(unsafe)` |
| `sending 'note' risks causing data races` in a main-queue observer | Copy the Sendable parts (an id, a pid) out of the notification before `MainActor.assumeIsolated` |
| Observer token captured before it is assigned | Keep the token in a small `@MainActor` class |
| "pattern that the region-based isolation checker does not understand" in a task group | Use an array of `Task { @MainActor in ... }` and await each one |
| Vars changed from `OperationQueue` blocks under `NSLock` | `OSAllocatedUnfairLock(initialState:)` |
| `@objc` action on an `NSMenuItem` subclass | `@MainActor @objc func` |

Done when the app builds with zero warnings in Swift 6 language mode,
`bin/test` passes, and the ticket's acceptance checks pass.
