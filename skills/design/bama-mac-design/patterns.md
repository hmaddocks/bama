# AppKit patterns for macOS

Code that compiles on macOS 26 with Swift 6 in the `bama-new-app` skeleton.
`Note` and `NotesViewController` are the example entity and list from
`bama-swift`'s
[appkit-recipes.md](../../code/bama-swift/appkit-recipes.md); rename them
to yours. The split view, table view, sheets, menu validation, and undo
with Core Data are there too.

Imports used across these snippets:

```swift
import Cocoa
import Carbon.HIToolbox
import UniformTypeIdentifiers
```

## Contents

- Global shortcut
- Quick-capture panel
- Toolbar that follows the columns
- Context menu, the Delete key, and feedback
- Search with recent searches
- Sortable table
- Drag to Finder makes a real file
- Restore the selection on relaunch
- Custom selection that follows the window
- Menu bar extra
- More patterns from real apps

## Global shortcut

No Accessibility permission needed. Carbon's hot key API still works on
macOS 26. Keep the `GlobalHotKey` object alive (store it on the app
delegate), or the shortcut stops working.

```swift
/// Calls `action` when the user presses the shortcut anywhere in macOS.
/// Example: GlobalHotKey(key: kVK_Space, modifiers: [.option]) { panel.toggle() }
@MainActor
final class GlobalHotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(key: Int, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        self.action = action
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, data in
            guard let data else { return noErr }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(data).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &spec, me, &handler)
        RegisterEventHotKey(UInt32(key), carbon, EventHotKeyID(signature: 0x4150_5031, id: 1), GetApplicationEventTarget(), 0, &ref)
    }

    isolated deinit {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
```

## Quick-capture panel

A Spotlight-style panel for the app's most frequent action. Pair it with
`GlobalHotKey` above. The field sits on glass because the panel floats
over other apps.

```swift
/// A floating panel without a title bar, like Spotlight. Escape closes it.
final class QuickCapturePanel: NSPanel, NSTextFieldDelegate {
    private let field = NSTextField()
    private let onSubmit: (String) -> Void

    init(placeholder: String, onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        super.init(contentRect: NSRect(x: 0, y: 0, width: 560, height: 64),
                   styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        level = .floating
        hidesOnDeactivate = true

        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .preferredFont(forTextStyle: .title3)
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false

        let glass = NSGlassEffectView()
        glass.cornerRadius = 16
        let content = NSView()
        content.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Space.xl),
            field.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Space.xl),
            field.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
        glass.contentView = content
        contentView = glass
    }

    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { orderOut(nil) }

    func toggle() {
        if isVisible { orderOut(nil); return }
        center()
        makeKeyAndOrderFront(nil)
        makeFirstResponder(field)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(insertNewline(_:)) else { return false }
        let text = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return true }
        onSubmit(text)   // optimistic: the caller saves, the panel closes right away
        field.stringValue = ""
        orderOut(nil)
        return true
    }
}
```

## Toolbar that follows the columns

A window with a sidebar, a list, and an inspector has three toolbar areas,
one over each column. Each button sits over the column it acts on:

```text
[traffic lights] [sidebar]  | Title           [+] [Search...] | [inspector]
     over the sidebar       |       over the list             | over the inspector
```

- The split view's items: `NSSplitViewItem(sidebarWithViewController:)`,
  the content, and `NSSplitViewItem(inspectorWithViewController:)`.
- Tracking separators split the toolbar at the columns:
  `.sidebarTrackingSeparator` and `.inspectorTrackingSeparator`.
- `.toggleSidebar` and `.toggleInspector` are system items. They work with
  the split view controller and get View menu commands from the system
  (View > Show Sidebar, Control-Command-S; View > Show Inspector,
  Control-Command-I). Add no second inspector command.
- Search over the list is an `NSSearchToolbarItem` in the content area.
- Set `window.toolbarStyle = .unified` and keep `.fullSizeContentView`, so
  the sidebar runs the window's full height.

```swift
extension NSToolbarItem.Identifier {
    static let newNote = Self("newNote")
    static let search = Self("search")
}

@MainActor
final class MainToolbar: NSObject, NSToolbarDelegate {
    let toolbar = NSToolbar(identifier: "Main")

    override init() {
        super.init()
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace, .newNote, .search,
         .inspectorTrackingSeparator, .flexibleSpace, .toggleInspector]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch id {
        case .newNote:
            let item = NSToolbarItem(itemIdentifier: id)
            item.label = "New Note"
            item.toolTip = "Add a note (Command-N)"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Note")
            item.action = #selector(NotesViewController.newNote(_:))   // first responder
            return item
        case .search:
            let item = NSSearchToolbarItem(itemIdentifier: id)
            item.searchField.placeholderString = "Search"
            item.preferredWidthForSearchField = 220
            return item
        default:
            return nil
        }
    }
}
```

Attach it in the window controller: `window.toolbar = mainToolbar.toolbar`,
and keep `mainToolbar` alive as a property. Check both states in a real
window capture (inspector open and closed), and once at the window's
minimum width: nothing overlaps the column edge, each button appears once,
and search is still reachable (toolbars.md, "Title and search").

## Context menu, the Delete key, and feedback

The table's context menu acts on the clicked row, or on the selection when
the clicked row is part of it. The Delete key and Edit > Delete go through
the same action.

```swift
extension NotesViewController: NSMenuDelegate {
    func installContextMenu() {
        let menu = NSMenu()
        menu.delegate = self
        table.menu = menu
    }

    /// The rows a context menu acts on: the selection when the clicked row
    /// is in it, else the clicked row alone.
    var clickedOrSelectedRows: IndexSet {
        let clicked = table.clickedRow
        if clicked < 0 || table.selectedRowIndexes.contains(clicked) { return table.selectedRowIndexes }
        return IndexSet(integer: clicked)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard !clickedOrSelectedRows.isEmpty else { return }
        menu.addItem(withTitle: "Delete", action: #selector(deleteClicked(_:)), keyEquivalent: "")
    }

    @objc private func deleteClicked(_ sender: Any?) {
        confirmDelete(notes(at: clickedOrSelectedRows))
    }

    /// The Delete key in the table. Keys like Delete are never menu shortcuts:
    /// they would fire while a text field has focus.
    override func keyDown(with event: NSEvent) {
        if event.specialKey == .delete || event.specialKey == .deleteForward {
            confirmDelete(selectedNotes)
        } else {
            super.keyDown(with: event)
        }
    }
}
```

For feedback on a change in place (starring, completing), animate the
symbol: `imageView.addSymbolEffect(.bounce)`, or swap it with
`imageView.setSymbolImage(newImage, contentTransition: .replace)`.

## Search with recent searches

Search starts broad, recent searches show before typing with a way to
clear them, and no results shows the query (design-rules.md rules 71 and
72). Filter the fetched results controller's predicate as the user types.

```swift
extension NotesViewController: NSSearchFieldDelegate {
    func configureSearch(_ field: NSSearchField) {
        field.delegate = self
        field.sendsSearchStringImmediately = true
        field.recentsAutosaveName = "NoteSearches"
        let template = NSMenu()
        let recentsTitle = NSMenuItem(title: "Recent Searches", action: nil, keyEquivalent: "")
        recentsTitle.tag = NSSearchField.recentsTitleMenuItemTag
        let recents = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        recents.tag = NSSearchField.recentsMenuItemTag
        let clear = NSMenuItem(title: "Clear Recent Searches", action: nil, keyEquivalent: "")
        clear.tag = NSSearchField.clearRecentsMenuItemTag
        let none = NSMenuItem(title: "No Recent Searches", action: nil, keyEquivalent: "")
        none.tag = NSSearchField.noRecentsMenuItemTag
        [recentsTitle, recents, .separator(), clear, none].forEach(template.addItem)
        field.searchMenuTemplate = template
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSSearchField else { return }
        search(field.stringValue)
    }

    func search(_ query: String) {
        // In fetch(): request.predicate = query.isEmpty ? nil
        //   : NSPredicate(format: "title CONTAINS[cd] %@", query)
        // When the results are empty and the query is not, show
        // "No Results for “\(query)”" over the table, so typos show.
    }
}
```

## Sortable table

Header click sorts and reverses, columns resize and remember their widths,
rows alternate, and long names truncate in the middle (rule 73).

```swift
extension NotesViewController {
    func configureSorting() {
        table.autosaveName = "NotesTable"
        table.autosaveTableColumns = true
        table.usesAlternatingRowBackgroundColors = true
        table.tableColumns[0].sortDescriptorPrototype = NSSortDescriptor(key: "title", ascending: true,
            selector: #selector(NSString.localizedStandardCompare(_:)))
        // In the cell: textField.lineBreakMode = .byTruncatingMiddle
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // Refetch with tableView.sortDescriptors as the request's sortDescriptors.
    }
}
```

## Drag to Finder makes a real file

A drag into Finder writes a file the app (or any app) can open again. Apps
that take no files get the title as text (rule 74).

```swift
final class NoteFilePromise: NSObject, NSFilePromiseProviderDelegate {
    let title: String
    let body: String

    init(title: String, body: String) {
        self.title = title
        self.body = body
    }

    func filePromiseProvider(_ provider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        "\(title).txt"
    }

    func filePromiseProvider(_ provider: NSFilePromiseProvider, writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        do {
            try "\(title)\n\n\(body)".write(to: url, atomically: true, encoding: .utf8)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}

// In the table's data source. Keep the promise alive until the drag ends
// (the provider's userInfo holds it here).
// func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//     let note = results.object(at: IndexPath(item: row, section: 0))
//     let promise = NoteFilePromise(title: note.title, body: "")
//     let provider = NSFilePromiseProvider(fileType: UTType.plainText.identifier, delegate: promise)
//     provider.userInfo = promise
//     return provider
// }
```

## Restore the selection on relaunch

Windows restore their frame with `setFrameAutosaveName`. Bring back other
UI state per window yourself: the selection, the open page, column widths
(`autosaveTableColumns`). Store a stable id, never the data itself
(rule 75).

```swift
extension NotesViewController {
    private static let selectionKey = "NotesSelection"

    func saveSelection() {
        let ids = selectedNotes.map(\.uuid.uuidString)
        UserDefaults.standard.set(ids, forKey: Self.selectionKey)
    }

    func restoreSelection(in notes: [Note]) {
        let ids = Set(UserDefaults.standard.stringArray(forKey: Self.selectionKey) ?? [])
        let rows = IndexSet(notes.indices.filter { ids.contains(notes[$0].uuid.uuidString) })
        table.selectRowIndexes(rows, byExtendingSelection: false)
        if let first = rows.first { table.scrollRowToVisible(first) }
    }
}
```

Call `saveSelection()` from `tableViewSelectionDidChange(_:)`, and
`restoreSelection(in:)` after the first fetch. Skip both when `APP_STORE`
is set, so snapshots always start the same way.

## Custom selection that follows the window

A custom selection fill uses the accent while the window is key and turns
grey when it is not, as system selection does (rules 14, 62, 63). AppKit
tells the row view through `isEmphasized`.

```swift
final class TintedRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        let fill: NSColor = isEmphasized ? .controlAccentColor : .unemphasizedSelectedContentBackgroundColor
        fill.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: Space.xs, dy: 1), xRadius: 6, yRadius: 6).fill()
    }
}

// In the table's delegate:
// func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? { TintedRowView() }
```

Prefer the system selection. Use this only when the design calls for a
selection the system does not draw, and record why in `CONTEXT.md`.

## Menu bar extra

An `NSStatusItem` for an always-available entry point. Let people turn it
off in Settings, and never make it the only way to reach a feature: the app
also has a Dock menu (menus.md). The icon is a template SF Symbol, so it
follows the menu bar's light and dark look. Show a menu. A panel is only
for a feature too complex for a menu (a timer with controls, a small
player). [HIG The menu bar]

```swift
@MainActor
final class StatusMenu: NSObject {
    private var item: NSStatusItem?

    func show(_ visible: Bool) {
        guard visible else {
            item.map(NSStatusBar.system.removeStatusItem)
            item = nil
            return
        }
        guard item == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "App")
        image?.isTemplate = true
        item.button?.image = image
        let menu = NSMenu()
        menu.addItem(withTitle: "Quick Add", action: #selector(quickAdd(_:)), keyEquivalent: "a").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        self.item = item
    }

    @objc private func quickAdd(_ sender: Any?) {}
}
```

## More patterns from real apps

Each one was built and checked in a shipped app.

### Highlight parts of a text field while typing

For inline highlights (dates, tags) in a one-line field, use a one-line
`NSTextView` and colour ranges with temporary attributes, which change the
look without changing the text:

```swift
@MainActor
func highlight(_ range: NSRange, in textView: NSTextView) {
    textView.layoutManager?.addTemporaryAttribute(.backgroundColor, value: NSColor.systemPurple.withAlphaComponent(0.16), forCharacterRange: range)
    textView.layoutManager?.addTemporaryAttribute(.foregroundColor, value: NSColor.systemPurple, forCharacterRange: range)
}
```

Override `keyDown` for Return (keyCode 36) and Escape (53), and
`mouseDown` with `characterIndexForInsertion(at:)` to react to clicks on a
highlight. Draw a placeholder in `draw(_:)` when the string is empty.

### Let a CLI wake the app instantly

When the app and a command-line tool share a store, the CLI can ping the
app after each write. `notify_post` is not visible to Swift; the
CoreFoundation Darwin center is the same mechanism:

```swift
func pingApp() {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFNotificationName("com.you.app.changed" as CFString), nil, nil, true)
}
```

The app adds an observer with `CFNotificationCenterAddObserver` and
refetches. With Core Data, persistent history tracking lets the app merge
exactly what the other process wrote.

### Services menu: "Add to MyApp" in every app

In Info.plist (the `info: properties:` of `project.yml`), an `NSServices`
entry with `NSMessage` (say `addTask`), `NSPortName`, and `NSSendTypes`
(`NSStringPboardType`). In `applicationDidFinishLaunching`:
`NSApp.servicesProvider = provider` and `NSUpdateDynamicServices()`. The
provider method signature is
`@objc func addTask(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>)`.
Test it without clicking: `NSPerformService("Add to MyApp", pasteboard)`
from a small Swift script.

### Menu bar extra that keeps the app alive

Show the status item, and return `false` from
`applicationShouldTerminateAfterLastWindowClosed` so closing the main
window keeps the menu bar and global shortcuts working. Reopen the window
from the status menu and from `applicationShouldHandleReopen(_:hasVisibleWindows:)`
(a click on the Dock icon).

### Notifications and the Dock badge

`NSApp.dockTile.badgeLabel = "3"` works right away. The badge counts only
unread notifications, never other numbers, and goes back to `nil` at zero.
A notification never says "open the app to do X", never repeats one
already shown, and offers at most four actions with title-case labels, none
of them "Open". Errors go in an alert inside the app, not a notification.
Notifications need the user's yes: if the permission prompt appears while
nobody is there, macOS records "denied" and `requestAuthorization` keeps
failing with "not allowed". Show the status in Settings and open
`x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=<bundle id>`.
Implement the delegate's `didReceive` as `nonisolated`, call the
completion handler right away, and hop to the main actor for the work.
Skip notifications, login items, and anything else with a system prompt
when `APP_STORE` is set, so tests never trigger a prompt.

### A floating capture panel without a title bar

Use `styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView]`,
`isOpaque = false`, `hasShadow = true`, and override `canBecomeKey` to
return true. A `.titled` panel with a hidden title bar still leaves an
empty strip on top.
