# AppKit recipes

Copyable code for the shapes most Mac apps need, built on the skeleton from
`bama-new-app`. Names use a `Note` entity with `title` and `uuid`; rename to
the glossary's terms. Every recipe compiles in Swift 6 language mode.

## Contents

- An entity in the core package
- Split view with a source list
- Table view backed by Core Data
- A sheet with a form
- Menu actions and validation
- Delete with confirmation and undo

## An entity in the core package

Add the entity to `<App>Core.xcdatamodeld` (attributes `title` String,
`uuid` UUID, `createdAt` Date; codegen Manual/None), then the class in
`<App>Core`:

```swift
import CoreData

@objc(Note)
public final class Note: NSManagedObject {
    @NSManaged public var title: String
    @NSManaged public var uuid: UUID
    @NSManaged public var createdAt: Date

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        NSFetchRequest<Note>(entityName: "Note")
    }

    /// Inserts a note with its defaults set.
    @discardableResult
    public static func insert(title: String, into context: NSManagedObjectContext) -> Note {
        let note = Note(context: context)
        note.title = title
        note.uuid = UUID()
        note.createdAt = .now
        return note
    }
}
```

Without `@objc(Note)`, Core Data looks for the class under its
module-qualified name and hands back a plain `NSManagedObject`.

## Split view with a source list

The main window's content: a sidebar and the selected page.

```swift
import Cocoa

enum SidebarPage: String, CaseIterable {
    case all, starred
    var title: String { self == .all ? "All Notes" : "Starred" }
    var symbol: String { self == .all ? "tray" : "star" }
}

final class MainSplitViewController: NSSplitViewController {
    private let sidebar = SidebarViewController()
    private let content: NotesViewController

    init(store: Store) {
        content = NotesViewController(store: store)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.minimumThickness = 180
        addSplitViewItem(sidebarItem)
        addSplitViewItem(NSSplitViewItem(viewController: content))
        sidebar.onSelect = { [content] page in content.show(page) }
    }
}

final class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onSelect: (SidebarPage) -> Void = { _ in }
    private let table = NSTableView()

    override func loadView() {
        table.style = .sourceList
        table.headerView = nil
        table.addTableColumn(NSTableColumn(identifier: .init("page")))
        table.dataSource = self
        table.delegate = self
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        view = scroll
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if table.selectedRow < 0 { table.selectRowIndexes([0], byExtendingSelection: false) }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { SidebarPage.allCases.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let page = SidebarPage.allCases[row]
        let cell = NSTableCellView()
        let image = NSImageView(image: NSImage(systemSymbolName: page.symbol, accessibilityDescription: nil)!)
        let text = NSTextField(labelWithString: page.title)
        let stack = NSStackView(views: [image, text])
        stack.spacing = Space.sm
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(stack)
        cell.imageView = image
        cell.textField = text
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Space.xs),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard table.selectedRow >= 0 else { return }
        onSelect(SidebarPage.allCases[table.selectedRow])
    }
}
```

In `MainWindowController`, replace `EmptyViewController()` with
`MainSplitViewController(store: store)`. Keep the `setContentSize` line
after it: a split view's own size is tiny. Then add a toolbar so the sidebar
gets its toggle (`bama-mac-design` toolbars.md).

## Table view backed by Core Data

An `NSFetchedResultsController` keeps the table in step with the store,
including undo and changes from an agent CLI.

```swift
import Cocoa
import CoreData

final class NotesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
    NSFetchedResultsControllerDelegate {
    let store: Store
    let table = NSTableView()
    private var results: NSFetchedResultsController<Note>!
    private var page: SidebarPage = .all

    init(store: Store) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        let column = NSTableColumn(identifier: .init("title"))
        column.title = "Title"
        table.addTableColumn(column)
        table.allowsMultipleSelection = true
        table.usesAutomaticRowHeights = true
        table.dataSource = self
        table.delegate = self
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        view = scroll
        fetch()
    }

    func show(_ page: SidebarPage) {
        self.page = page
        fetch()
    }

    private func fetch() {
        let request = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: store.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        results.delegate = self
        try? results.performFetch()
        table.reloadData()
    }

    var selectedNotes: [Note] {
        table.selectedRowIndexes.map { results.object(at: IndexPath(item: $0, section: 0)) }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { results?.fetchedObjects?.count ?? 0 }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let note = results.object(at: IndexPath(item: row, section: 0))
        let id = NSUserInterfaceItemIdentifier("note")
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView ?? {
            let cell = NSTableCellView()
            cell.identifier = id
            let text = NSTextField(labelWithString: "")
            text.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(text)
            cell.textField = text
            NSLayoutConstraint.activate([
                text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: Space.xs),
                text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -Space.xs),
                text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])
            return cell
        }()
        cell.textField?.stringValue = note.title
        return cell
    }

    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        MainActor.assumeIsolated { table.reloadData() }
    }
}
```

`reloadData()` is right for lists up to a few thousand rows. For animated
inserts and moves, switch to `NSTableViewDiffableDataSource` keyed by
`NSManagedObjectID`.

## A sheet with a form

Labels right-aligned beside their fields, in an `NSGridView`. The sheet
edits a copy of the values and writes them back on Save, so Cancel leaves
the store untouched.

```swift
import Cocoa

final class NoteSheetController: NSViewController, NSTextFieldDelegate {
    private let titleField = NSTextField()
    private let saveButton: NSButton
    private let onSave: (String) -> Void

    init(title: String, saveTitle: String, onSave: @escaping (String) -> Void) {
        self.onSave = onSave
        saveButton = NSButton(title: saveTitle, target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
        titleField.stringValue = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        titleField.placeholderString = "Title"
        titleField.delegate = self
        let grid = NSGridView(views: [[NSTextField(labelWithString: "Title:"), titleField]])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.columnSpacing = Space.sm
        titleField.widthAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.keyEquivalent = "\u{1b}"
        saveButton.target = self
        saveButton.action = #selector(save(_:))
        saveButton.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, saveButton])
        buttons.spacing = Space.sm

        let stack = NSStackView(views: [grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = Space.xl
        stack.edgeInsets = NSEdgeInsets(top: Space.xl, left: Space.xl, bottom: Space.xl, right: Space.xl)
        view = stack
        updateSave()
    }

    func controlTextDidChange(_ obj: Notification) { updateSave() }

    private func updateSave() {
        saveButton.isEnabled = !titleField.stringValue.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @objc private func save(_ sender: Any?) {
        onSave(titleField.stringValue.trimmingCharacters(in: .whitespaces))
        dismiss(self)
    }

    @objc private func cancel(_ sender: Any?) { dismiss(self) }
}
```

Present it from the window's view controller:

```swift
presentAsSheet(NoteSheetController(title: "", saveTitle: "Add") { [store] title in
    Note.insert(title: title, into: store.viewContext)
    store.viewContext.undoManager?.setActionName("Add Note")
    try? store.save()
})
```

Register the sheet as a snapshot page that presents it and returns
`view.window?.attachedSheet`.

## Menu actions and validation

Actions go to the first responder, so the view controller that owns the
selection handles them. Add the items to `MainMenu.xib` (or in code) with
target First Responder.

```swift
extension NotesViewController: NSMenuItemValidation {
    @IBAction func newNote(_ sender: Any?) {
        presentAsSheet(NoteSheetController(title: "", saveTitle: "Add") { [store] title in
            Note.insert(title: title, into: store.viewContext)
            store.viewContext.undoManager?.setActionName("Add Note")
            try? store.save()
        })
    }

    @IBAction func delete(_ sender: Any?) {
        confirmDelete(selectedNotes)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(delete(_:)):
            let count = selectedNotes.count
            menuItem.title = count > 1 ? "Delete \(count) Notes" : "Delete"
            return count > 0
        default:
            return true
        }
    }
}
```

The view controller must be in the responder chain: the table is first
responder, and a view controller's view's next responder is the view
controller.

## Delete with confirmation and undo

A destructive alert, with Cancel as the default button, then one undo step
for the whole delete.

```swift
extension NotesViewController {
    func confirmDelete(_ notes: [Note]) {
        guard !notes.isEmpty, let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = notes.count == 1 ? "Delete \u{201C}\(notes[0].title)\u{201D}?" : "Delete \(notes.count) notes?"
        alert.informativeText = "You can undo this with Edit > Undo."
        let delete = alert.addButton(withTitle: "Delete")
        delete.hasDestructiveAction = true
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\r"
        delete.keyEquivalent = ""
        alert.beginSheetModal(for: window) { [store] response in
            guard response == .alertFirstButtonReturn else { return }
            let undo = store.viewContext.undoManager
            undo?.beginUndoGrouping()
            notes.forEach(store.viewContext.delete)
            undo?.endUndoGrouping()
            undo?.setActionName(notes.count == 1 ? "Delete Note" : "Delete Notes")
            try? store.save()
        }
    }
}
```

The fetched results controller sees the delete, and the undo, and updates
the table on its own.
