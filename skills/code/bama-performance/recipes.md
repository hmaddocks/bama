# Performance recipes

Each recipe names the symptom, the cause, and the fix. Most come from real
bugs in shipped apps.

## Contents

- Main thread
- Show first, work after
- Drawing: let the GPU composite
- Images
- Lists and table views
- Background work with Swift concurrency
- Timers, polling, and energy
- Measuring

## Main thread

**Symptom:** the whole app freezes, the pointer spins.
**Cause:** a call on the main thread that waits on something slow.

- `NSSound.play()` blocked the main thread for minutes while CoreAudio was
  busy after a screen recording. Fix: `AudioServicesPlaySystemSound` with a
  sound ID made once, called off the main thread.
- Accessibility calls (`AXUIElementCopyAttributeValue`) wait for the other
  app to answer. A stuck app stalls you. Fix:
  `AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.0)` once
  at launch, and never call AX in a loop on the main thread.
- File, network, and large store reads in `viewDidLoad`, `viewWillAppear`,
  or a table's `viewFor` callback. Fix: start a `Task { }` that awaits a
  `nonisolated` or `@concurrent` function (or `performBackgroundTask`), then
  update the view on the main actor.

Find the frozen call:

```bash
sample <AppName> 5 -file /tmp/<AppName>-sample.txt   # 5 s of stacks
grep -A30 "Thread_.*main" /tmp/<AppName>-sample.txt | head -60
```

## Show first, work after

**Symptom:** a shortcut feels slow even when the work is fast.
**Cause:** the UI waits for the work before it appears.

Show the window, panel, or picker in the same frame as the key press. Do
the slow part after, and fill it in when it lands. A screenshot
picker shows at once, see-through, and captures every display in parallel
behind it. A drag that ends before the capture lands waits for it.

```swift
picker.show()                                   // same frame as the key press
Task {
    await withTaskGroup(of: (Int, CGImage?).self) { group in
        for (i, display) in displays.enumerated() {
            group.addTask { (i, try? await capture(display)) }
        }
        for await (i, image) in group { if let image { pickers[i].freeze(image) } }
    }
}
```

Optimistic UI is the same rule for data: close the panel on Return, show
the new row, save in the background, offer Undo.

## Drawing: let the GPU composite

**Symptom:** dragging or moving the mouse over a big image stutters.
**Cause:** the CPU redraws the full picture on every event.

- Put the big picture in a `CALayer` once (`layer.contents = cgImage`). The
  GPU composites it. On mouse move, change only a small layer's `frame`
  or `path` (selection box, crosshair, label).
- Turn off implicit layer animations for layers that follow the pointer:

  ```swift
  layer.actions = ["position": NSNull(), "bounds": NSNull(), "frame": NSNull(),
                   "contents": NSNull(), "path": NSNull()]
  ```

- In an editor, draw the picture once as its own layer, and redraw only the
  shapes on top while the user drags.
- Never draw a full-screen image in `draw(_:)` per mouse move. A 5K screen
  is 15 million pixels per frame.
- A complex static view (many shapes, gradients): give it a layer
  (`wantsLayer = true`), draw once, and set
  `layerContentsRedrawPolicy = .onSetNeedsDisplay`, so it redraws only when
  asked.
- Many shadows and blurs on list rows cost a lot. Use one shadow on the
  container, not one per row.
- Image filters (blur, pixelate): one shared `CIContext`, made once, which
  renders on the GPU with Metal. Never make a `CIContext` per call.

## Images

- Thumbnails: decode at the size you show with ImageIO, not with a full
  `NSImage`:

  ```swift
  let src = CGImageSourceCreateWithURL(url as CFURL, nil)!
  let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: 400,
      kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary)
  ```

- Cache decoded thumbnails in an `NSCache` keyed by URL and size.
- Text recognition (Vision `RecognizeTextRequest`) runs off the main
  thread, after the picture is on screen.

## Lists and table views

- Use `NSTableView` or `NSOutlineView` for anything longer than a screen.
  They make cells only for visible rows and reuse them
  (`makeView(withIdentifier:owner:)`). A stack view of rows builds every
  row.
- Reload only what changed: `reloadData(forRowIndexes:columnIndexes:)`, or
  `insertRows`/`removeRows` inside `beginUpdates`/`endUpdates`. A full
  `reloadData()` on every keystroke of a search is fine up to a few
  thousand rows; measure before going further.
- Live lists (search results, a window switcher) do not animate. Speed wins
  over motion.
- Sort and filter in the core package or in the fetch request, not in
  `tableView(_:viewFor:row:)`, which runs for every visible row on every
  scroll.
- Row heights: `usesAutomaticRowHeights` measures every row it shows.
  Fixed heights (`rowHeight`) are cheaper for long uniform lists.

## Core Data

- Sort and filter in the fetch request (`sortDescriptors`, `predicate`), so
  SQLite does the work. Sorting fetched objects in Swift fires a fault per
  object.
- Min and max: a fetch request with a sort and `fetchLimit = 1`, not a
  fetch of every object.
- Counts: `count(for:)`, not `fetch(...).count`.
- Big lists: `fetchBatchSize` (about two screens of rows) keeps memory flat;
  `propertiesToFetch` with `.dictionaryResultType` for read-only summaries.
- Bulk changes: `NSBatchUpdateRequest` and `NSBatchDeleteRequest` run in
  SQLite, then merge the changes into the view context
  (`NSManagedObjectContext.mergeChanges(fromRemoteContextSave:into:)`).
- Heavy imports run in `performBackgroundTask`, saving every few hundred
  objects; the view context merges them automatically.
- `objectID` changes on the first save. Select and look up by the entity's
  `uuid` attribute.

## Background work with Swift concurrency

The template uses main-actor default isolation: everything runs on the main
actor unless you say otherwise.

- Heavy pure work: a `nonisolated` function marked `@concurrent` runs on the
  shared pool. Await it from the view or model.
- Shared mutable state used off the main thread: an `actor`.
- `Task.detached` only when the work must not inherit the caller's actor or
  priority.
- Hand results back to the main actor before you touch UI state.

## Timers, polling, and energy

- Poll fast only while it matters. Permission checks: every 1 to 2 s
  while a permission is missing or a view that shows it is open, otherwise
  every 20 s.
- Give every repeating timer a tolerance (`timer.tolerance = interval / 10`)
  so macOS can group wake-ups.
- Sample system stats only while someone looks at them (menu open, page
  visible). Stop the timer when the popover closes.
- Prefer notifications to polling: `NSWorkspace` notifications for app
  launch and activation, Darwin notifications (`notify_post`) for pings
  from a CLI, `NSPasteboard.changeCount` checks at most twice a second.

## Measuring

Measure the release build. Debug builds are 3 to 10 times slower in
Swift and lie about where the time goes.

```bash
# CPU: where time goes
xcrun xctrace record --template 'Time Profiler' --attach <AppName> \
  --time-limit 10s --output /tmp/<AppName>.trace
# Hangs on the main thread
xcrun xctrace record --template 'Hangs' --attach <AppName> --time-limit 20s \
  --output /tmp/<AppName>-hangs.trace
# Memory
footprint <AppName>
leaks <AppName>
```

Open the `.trace` in Instruments, or export a table:
`xcrun xctrace export --input /tmp/<AppName>.trace --toc`.

Add signposts around the work you want to time, so traces show it by name:

```swift
let signposter = OSSignposter(subsystem: "com.you.app", category: "capture")
let state = signposter.beginInterval("freeze")
// ...
signposter.endInterval("freeze", state)
```

### First frame from a script

"Feels slow" is a number once you log three times for an action: blocked
(how long the call took), visible (window on screen), and frame (the first
frame committed). In the app, after the action:

```swift
let start = CACurrentMediaTime()
let observer = CFRunLoopObserverCreateWithHandler(nil,
    CFRunLoopActivity.beforeWaiting.rawValue, false, CFIndex.max) { obs, _ in
    log("frame \((CACurrentMediaTime() - start) * 1000) ms")   // runs after Core Animation's commit
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), obs, .commonModes)
}
CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
```

Run it six times. The first run is the cold one; report it apart. When a
feature waits on purpose (a switcher that shows only after 90 ms, so a
quick tap never flashes), measure from the end of that wait.

### Traces as text

```bash
xcrun xctrace export --input /tmp/App.trace --toc
xcrun xctrace export --input /tmp/App.trace \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="time-profile"]' > /tmp/profile.xml
```

The XML refers to repeated frames by `ref` id. A short script that resolves
the ids and prints the callee tree under one function shows the cause in
one step. Delete the `.trace` and the XML afterwards: they hold the app's
environment, secrets included.

### Causes found this way

- **Panels with a text field**: a first-responder change on a window with
  a hosted SwiftUI view re-runs SwiftUI's focus graph (10 to 15 ms each).
  In a hosted piece, do not call `makeFirstResponder` in `show()`. Resign
  the old field while hiding, and focus the field one turn later.
- `NSRunningApplication.icon` asks NSWorkspace on every call (about 1 ms per
  app). Cache icons per process id.
- **Cold first open**: a panel and its hosting view built on the first key
  press. Build shortcut panels a few seconds after launch (prewarm).
- `sample` helps for freezes, not for events under 100 ms. Use a trace
  around a probe loop instead.

### Probe commands

For an agent, the quickest loop is a probe command in the debug bridge
(see the `bama-test-app` skill): it runs the action, logs how long each
step took, and writes the numbers to `status.json`. Then compare before
and after a change.
