# Where a feature opens

Code for each row of the surface table in [SKILL.md](SKILL.md). It compiles
on macOS 26 with Swift 6 in the `bama-new-app` skeleton. `Note`,
`NotesViewController`, and `NoteSheetController` come from `bama-swift`'s
[appkit-recipes.md](../../code/bama-swift/appkit-recipes.md).

## Contents

- Inline
- Inspector
- Popover
- Panel
- Sheet
- New window
- Sidebar page or detail
- Confirmation dialog
- Alert
- Status instead of an alert
- Unsaved changes

## Inline

Use for one value on something already on screen. No surface opens, so
nothing needs closing. Save on Return or when focus leaves the field: make
the cell's text field editable, and save in its action.

```swift
extension NotesViewController {
    /// Call when making a row's cell: the title edits in place.
    func makeEditable(_ field: NSTextField) {
        field.isEditable = true
        field.target = self
        field.action = #selector(titleEdited(_:))
    }

    @objc func titleEdited(_ sender: NSTextField) {
        let row = table.row(for: sender)
        guard row >= 0 else { return }
        let note = notes(at: IndexSet(integer: row))[0]
        let title = sender.stringValue.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, title != note.title else { sender.stringValue = note.title; return }
        note.title = title
        store.viewContext.undoManager?.setActionName("Rename Note")
        try? store.save()
    }
}
```

## Inspector

Use for details of the selection while people keep working in the list.
It stays open across selections. It is a split view item, with the system
`.toggleInspector` toolbar item and View > Show Inspector,
Control-Command-I (bama-mac-design toolbars.md).

```swift
final class NoteInspectorController: NSViewController {
    private let noteTitle = NSTextField(labelWithString: "")
    private let empty = NSTextField(labelWithString: "No Selection")

    override func loadView() {
        empty.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [noteTitle, empty])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: Space.xl, left: Space.lg, bottom: Space.xl, right: Space.lg)
        view = stack
    }

    func show(_ note: Note?) {
        noteTitle.stringValue = note?.title ?? ""
        noteTitle.isHidden = note == nil
        empty.isHidden = note != nil
    }
}

// In MainSplitViewController.viewDidLoad:
// let inspector = NSSplitViewItem(inspectorWithViewController: inspectorController)
// inspector.minimumThickness = 220
// inspector.maximumThickness = 360
// addSplitViewItem(inspector)
```

## Popover

Use for a few related choices tied to one control. It closes when people
click outside or pick an item, and it keeps their changes. Only an explicit
Cancel throws them away. It never warns, never holds a warning, and opens
one at a time. A popover people want to keep open can detach into a panel
(`NSPopoverDelegate.detachableWindow(for:)`).

```swift
@MainActor
func showDatePopover(from button: NSButton, date: Date, onChange: @escaping (Date) -> Void) {
    let picker = NSDatePicker()
    picker.datePickerStyle = .clockAndCalendar
    picker.datePickerElements = .yearMonthDay
    picker.dateValue = date
    let controller = DatePopoverController(picker: picker, onChange: onChange)
    let popover = NSPopover()
    popover.behavior = .transient          // closes on a click outside
    popover.contentViewController = controller
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
}

final class DatePopoverController: NSViewController {
    private let picker: NSDatePicker
    private let onChange: (Date) -> Void

    init(picker: NSDatePicker, onChange: @escaping (Date) -> Void) {
        self.picker = picker
        self.onChange = onChange
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        picker.target = self
        picker.action = #selector(changed(_:))   // keeps each change, like the system
        let stack = NSStackView(views: [picker])
        stack.edgeInsets = NSEdgeInsets(top: Space.md, left: Space.md, bottom: Space.md, right: Space.md)
        view = stack
    }

    @objc private func changed(_ sender: NSDatePicker) { onChange(sender.dateValue) }
}
```

## Panel

Use when people give input again and again and watch the result (find and
replace, a colour or font picker), or keep a tool open beside their work.
A panel floats over the app, hides when the app is not in front, has no
minimize button, and stays out of the Window menu's list. Its title is a
noun ("Inspector"), and its menu item says "Show Inspector", never "panel".

```swift
@MainActor
func makeUtilityPanel(title: String, content: NSViewController) -> NSPanel {
    let panel = NSPanel(contentViewController: content)
    panel.styleMask = [.titled, .closable, .utilityWindow, .resizable]
    panel.title = title
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = true
    panel.isExcludedFromWindowsMenu = true
    panel.isRestorable = false
    panel.setFrameAutosaveName(title)
    return panel
}
```

Prefer sliders, steppers, and pop-up buttons over typed values in a panel.

A Spotlight-style panel, a corner card, a countdown, or a HUD is a
different kind: borderless, non-activating, it closes when it loses focus
and stays out of screen recordings. Recipe: bama-mac-design patterns.md,
"Quick-capture panel", and bama-os-integrations recipes.md, "Non-activating
panel".

## Sheet

Use for one short task that must finish or cancel before going on: a few
fields, one screen, no navigation inside. Buttons sit at the bottom
trailing edge, Return confirms, Escape cancels. The recipe is
`NoteSheetController` in appkit-recipes.md, presented with
`presentAsSheet`.

- A Done button always comes with Cancel, or with Back in a multi-step
  sheet. Never show Cancel, Done, and Back together.
- Open at a size that fits the content. Let people resize it when the
  content would benefit (a long list, a preview).
- Other windows of the app stay usable while the sheet is open.
- People repeat the input and watch results? Use a panel instead.

A sheet that grows a second screen, a sidebar, or a scroll of settings
wants to be a window.

## New window

Use for a long or self-contained task, or something people keep open next
to the main window: an editor, a large preview. Each window remembers its
frame. One window controller per open object, kept by id so a second
"Open" brings the same window forward.

```swift
@MainActor
final class NoteWindows {
    private var open: [UUID: NSWindowController] = [:]

    func show(_ note: Note, content: () -> NSViewController) {
        if let existing = open[note.uuid] {
            existing.showWindow(nil)
            return
        }
        let window = NSWindow(contentViewController: content())
        window.title = note.title
        window.setContentSize(NSSize(width: 640, height: 480))
        window.isRestorable = false
        window.setFrameAutosaveName("Note \(note.uuid)")
        let controller = NSWindowController(window: window)
        open[note.uuid] = controller
        controller.showWindow(nil)
    }
}
```

Remove the controller from `open` in the window delegate's
`windowWillClose(_:)`.

## Sidebar page or detail

A place people come back to (Inbox, Today, a project) is a sidebar page.
One item of that list opens in the detail column or the inspector, not in a
sheet. Register it as a snapshot page in `AppDelegate.snapshotPages` so snapshot mode visits it.

## Confirmation dialog

Use only for a rare action that destroys data and cannot be undone. For
undoable actions, act at once and offer Undo. The title asks the question,
the button repeats the verb, and Cancel is there too.

When people chose the action on purpose (Empty Trash from a menu), the
confirm button is not marked destructive, so Return confirms what they
asked for. Set `hasDestructiveAction` only on a destructive button people
did not ask for, such as "Don't Save" when closing an edited document.
[HIG Buttons]

```swift
@MainActor
func confirmEmptyTrash(in window: NSWindow, emptyTrash: @escaping () -> Void) {
    let alert = NSAlert()
    alert.messageText = "Empty Trash?"
    alert.informativeText = "You can\u{2019}t undo this action."
    alert.addButton(withTitle: "Empty Trash")
    alert.addButton(withTitle: "Cancel")
    alert.beginSheetModal(for: window) { response in
        if response == .alertFirstButtonReturn { emptyTrash() }
    }
}
```

## Alert

Use for a problem people must act on now. The title says what happened.
The message, if any, says what to do.

- Never at launch, never only to inform, and never for a common delete
  that Undo covers.
- The default button sits on the trailing side. Escape and Command-Period
  cancel. Avoid "OK" except for a purely informational alert.
- An alert that repeats for a task people do often gets a "Do not show
  again" checkbox: `alert.showsSuppressionButton = true`, then read
  `alert.suppressionButton?.state`.
- The caution symbol only for a real risk of losing data, never for a
  routine overwrite or Empty Trash.

```swift
@MainActor
func showExportFailed(in window: NSWindow, chooseFolder: @escaping () -> Void) {
    let alert = NSAlert()
    alert.messageText = "Unable to Export"
    alert.informativeText = "The folder is read-only. Choose a folder you can write to."
    alert.addButton(withTitle: "Choose Another Folder")
    alert.addButton(withTitle: "Cancel")
    alert.beginSheetModal(for: window) { response in
        if response == .alertFirstButtonReturn { chooseFolder() }
    }
}
```

## Status instead of an alert

Information that needs no action goes where it applies. Offline, show the
cached content and a quiet label, the way Mail does.

```swift
@MainActor
func makeOfflineLabel() -> NSView {
    let image = NSImageView(image: NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: nil)!)
    image.contentTintColor = .secondaryLabelColor
    let text = NSTextField(labelWithString: "Offline. Changes save when you reconnect.")
    text.font = .preferredFont(forTextStyle: .callout)
    text.textColor = .secondaryLabelColor
    let stack = NSStackView(views: [image, text])
    stack.spacing = Space.xs
    stack.edgeInsets = NSEdgeInsets(top: Space.sm, left: Space.sm, bottom: Space.sm, right: Space.sm)
    return stack   // pin it to the bottom of the list's view; hide it when online
}
```

## Unsaved changes

Ask before closing only when people would lose what they typed. Offer to
keep it.

```swift
@MainActor
func cancelEditing(draft: String, in window: NSWindow, dismiss: @escaping () -> Void) {
    guard !draft.isEmpty else { dismiss(); return }
    let alert = NSAlert()
    alert.messageText = "Discard this note?"
    let discard = alert.addButton(withTitle: "Discard")
    discard.hasDestructiveAction = true
    alert.addButton(withTitle: "Keep Editing")
    alert.beginSheetModal(for: window) { response in
        if response == .alertFirstButtonReturn { dismiss() }
    }
}
```
