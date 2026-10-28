# UIKit recipes

Copyable code for the shapes most iPhone and iPad apps need, built on the
skeleton from `bama-new-app`. The app is called `Notes`, so the core
package is `NotesCore`; use your app's names and the glossary's terms. The
`Note` entity is the one in [appkit-recipes.md](appkit-recipes.md), "An
entity in the core package": both targets share it. Every recipe compiles
in Swift 6 language mode for the iOS 26 simulator.

## Contents

- Split view with a tab bar in compact width
- A list backed by Core Data
- A form in a sheet
- Add, rename, and delete with undo
- Swipe actions and context menus
- Snapshot pages

## Split view with a tab bar in compact width

The window root on every device, the way Cashflow's
`RootSplitViewController` works. An iPad shows a sidebar and the selected
page. An iPhone, and an iPad window made narrow,
shows a tab bar with the same pages. Both layouts read one `page`, so
switching between them keeps the place.

```swift
import UIKit
import NotesCore

enum SidebarPage: Int, CaseIterable {
    case all, recent
    var title: String { self == .all ? "All Notes" : "Recent" }
    var symbol: String { self == .all ? "tray" : "clock" }
}

/// The window root on every device. Regular width shows a sidebar and the
/// selected page. Compact width shows a tab bar with the same pages, in the
/// same order, with the same symbols.
final class RootSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    private let store: Store
    private let sidebar = SidebarViewController()
    private let detail = UINavigationController()
    private let tabs = UITabBarController()
    private(set) var page: SidebarPage = .all

    init(store: Store) {
        self.store = store
        super.init(style: .doubleColumn)
        delegate = self
        // An iPhone always gets the tab bar, even the large ones whose
        // landscape width is regular.
        if UIDevice.current.userInterfaceIdiom == .phone {
            traitOverrides.horizontalSizeClass = .compact
        }
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .oneBesideSecondary

        tabs.viewControllers = SidebarPage.allCases.map { page in
            let list = UINavigationController(rootViewController: NotesViewController(store: store, page: page))
            list.tabBarItem = UITabBarItem(title: page.title, image: UIImage(systemName: page.symbol), tag: page.rawValue)
            return list
        }
        sidebar.onSelect = { [weak self] page in self?.show(page) }
        setViewController(sidebar, for: .primary)
        setViewController(detail, for: .secondary)
        setViewController(tabs, for: .compact)
        show(.all)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Shows `page` in the main column and selects it in the sidebar and
    /// the tab bar, so both layouts agree.
    func show(_ page: SidebarPage) {
        self.page = page
        sidebar.select(page)
        tabs.selectedIndex = page.rawValue
        detail.setViewControllers([NotesViewController(store: store, page: page)], animated: false)
        // A sidebar that covers the main column (iPad portrait) hides after a tap.
        if displayMode == .oneOverSecondary { show(.secondary) }
    }

    // Narrowing (a narrow iPad window): the tab for the page shown.
    func splitViewController(_ svc: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: Column) -> Column {
        tabs.selectedIndex = page.rawValue
        return .compact
    }

    // Widening: the sidebar shows the tab that was selected.
    func splitViewController(_ svc: UISplitViewController,
                             displayModeForExpandingToProposedDisplayMode proposedDisplayMode: DisplayMode) -> DisplayMode {
        show(SidebarPage(rawValue: tabs.selectedIndex) ?? .all)
        return proposedDisplayMode
    }

    // MARK: Undo

    /// Shake, three-finger swipes and Command-Z ask the first responder for
    /// an undo manager; views that do not override it fall through to here.
    override var undoManager: UndoManager? { store.viewContext.undoManager }

    /// iOS 26 refuses first responder to container view controllers, which
    /// leaves shake with no responder. A hidden view takes it instead, and
    /// its undoManager falls through the responder chain to the override.
    private let undoResponder = UndoResponderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        undoResponder.isHidden = true
        view.addSubview(undoResponder)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        undoResponder.becomeFirstResponder()
    }
}

final class UndoResponderView: UIView {
    override var canBecomeFirstResponder: Bool { true }
}
```

The sidebar is a list in the `.sidebar` appearance:

```swift
import UIKit

final class SidebarViewController: UICollectionViewController {
    var onSelect: (SidebarPage) -> Void = { _ in }
    private var dataSource: UICollectionViewDiffableDataSource<Int, SidebarPage>!

    init() {
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(
            using: UICollectionLayoutListConfiguration(appearance: .sidebar)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        let cell = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarPage> { cell, _, page in
            var content = UIListContentConfiguration.cell()
            content.text = page.title
            content.image = UIImage(systemName: page.symbol)
            cell.contentConfiguration = content
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { view, path, page in
            view.dequeueConfiguredReusableCell(using: cell, for: path, item: page)
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, SidebarPage>()
        snapshot.appendSections([0])
        snapshot.appendItems(SidebarPage.allCases)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func select(_ page: SidebarPage) {
        loadViewIfNeeded()
        collectionView.selectItem(at: IndexPath(item: page.rawValue, section: 0), animated: false, scrollPosition: [])
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect(SidebarPage.allCases[indexPath.item])
    }
}
```

In `SceneDelegate`, replace `RootViewController(store: store)` with
`RootSplitViewController(store: store)`. Its `undoManager` override
replaces the one `RootViewController` had.

When every page is a tab and the sidebar holds nothing else,
`UITabBarController` with `mode = .tabSidebar` is shorter: it shows a
sidebar on iPad and a tab bar on iPhone by itself.

## A list backed by Core Data

A collection view list with a diffable data source, fed by an
`NSFetchedResultsController`. Changes from anywhere (undo, an agent CLI,
iCloud) update the list.

```swift
import UIKit
import CoreData
import NotesCore

/// A list of notes kept in step with the store by a fetched results
/// controller, including undo and changes from an agent CLI.
final class NotesViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    let store: Store
    let page: SidebarPage
    private var results: NSFetchedResultsController<Note>!
    private var dataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!

    init(store: Store, page: SidebarPage) {
        self.store = store
        self.page = page
        // viewDidLoad replaces the layout with one that has swipe actions,
        // which need self.
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(
            using: UICollectionLayoutListConfiguration(appearance: .insetGrouped)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = page.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.addNote()
        })
        var list = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        list.trailingSwipeActionsConfigurationProvider = { [weak self] path in
            self?.swipeActions(at: path)
        }
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: list)

        let cell = UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> { [store] cell, _, id in
            guard let note = try? store.viewContext.existingObject(with: id) as? Note else { return }
            var content = cell.defaultContentConfiguration()
            content.text = note.title
            content.secondaryText = note.createdAt.formatted(date: .abbreviated, time: .omitted)
            cell.contentConfiguration = content
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { view, path, id in
            view.dequeueConfiguredReusableCell(using: cell, for: path, item: id)
        }

        let request = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if page == .recent {
            request.predicate = NSPredicate(format: "createdAt > %@", Date.now.addingTimeInterval(-7 * 86_400) as NSDate)
        }
        results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: store.viewContext,
                                             sectionNameKeyPath: nil, cacheName: nil)
        results.delegate = self
        try? results.performFetch()
    }

    nonisolated func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                                didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        MainActor.assumeIsolated {
            // The results controller does not mark edited rows. Reconfigure
            // the ones already shown, so a rename appears.
            let shown = Set(dataSource.snapshot().itemIdentifiers)
            snapshot.reconfigureItems(snapshot.itemIdentifiers.filter(shown.contains))
            dataSource.apply(snapshot, animatingDifferences: view.window != nil)
            setNeedsUpdateContentUnavailableConfiguration()
        }
    }

    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        guard results?.fetchedObjects?.isEmpty ?? false else {
            contentUnavailableConfiguration = nil
            return
        }
        var empty = UIContentUnavailableConfiguration.empty()
        empty.image = UIImage(systemName: "note.text")
        empty.text = "No Notes"
        empty.secondaryText = "Tap + to write your first note."
        contentUnavailableConfiguration = empty
    }

    func note(at path: IndexPath) -> Note? {
        dataSource.itemIdentifier(for: path).flatMap { try? store.viewContext.existingObject(with: $0) as? Note }
    }
}
```

The results controller hands over a snapshot of object IDs. It does not
mark rows whose object changed, so the delegate reconfigures the rows
already shown, or a rename would not appear.

## A form in a sheet

A form sheet with Cancel and Save in its navigation bar. It edits a copy
and hands the values back on Save. Once the user types, a swipe down no
longer dismisses it (`isModalInPresentation`).

```swift
import UIKit

/// A form in a sheet. It edits a copy of the values and hands them back on
/// Save, so Cancel leaves the store untouched.
final class NoteFormViewController: UIViewController, UITextFieldDelegate {
    private let titleField = UITextField()
    private let original: String
    private let onSave: (String) -> Void

    init(title: String, heading: String, onSave: @escaping (String) -> Void) {
        original = title
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        titleField.text = title
        navigationItem.title = heading
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Wraps the form in a navigation controller for its Cancel and Save bar.
    static func sheet(title: String, heading: String, onSave: @escaping (String) -> Void) -> UINavigationController {
        let sheet = UINavigationController(rootViewController: NoteFormViewController(title: title, heading: heading, onSave: onSave))
        sheet.modalPresentationStyle = .formSheet
        sheet.sheetPresentationController?.detents = [.medium(), .large()]
        return sheet
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            self?.save()
        })
        navigationItem.rightBarButtonItem?.style = .prominent

        titleField.placeholder = "Title"
        titleField.borderStyle = .roundedRect
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true
        titleField.clearButtonMode = .whileEditing
        titleField.returnKeyType = .done
        titleField.delegate = self
        titleField.addAction(UIAction { [weak self] _ in self?.update() }, for: .editingChanged)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleField)
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Space.xl),
            titleField.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
        ])
        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleField.becomeFirstResponder()
    }

    private var trimmed: String { (titleField.text ?? "").trimmingCharacters(in: .whitespaces) }

    private func update() {
        navigationItem.rightBarButtonItem?.isEnabled = !trimmed.isEmpty
        // A swipe down would lose typed text, so it is blocked once there is some.
        isModalInPresentation = trimmed != original
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !trimmed.isEmpty { save() }
        return false
    }

    private func save() {
        onSave(trimmed)
        dismiss(animated: true)
    }
}
```

On iPhone it opens at half height (`.medium()`) and grows with the
keyboard. On iPad `.formSheet` centres it. Forms with several fields are a
`UICollectionView` list in `.insetGrouped` appearance, one cell per field.

## Add, rename, and delete with undo

Every change is one save with an action name, so shake to undo, the
three-finger swipe, and Command-Z on a keyboard all name it.

```swift
import UIKit
import NotesCore

extension NotesViewController {
    func addNote() {
        present(NoteFormViewController.sheet(title: "", heading: "New Note") { [store] title in
            Note.insert(title: title, into: store.viewContext)
            store.viewContext.undoManager?.setActionName("Add Note")
            try? store.save()
        }, animated: true)
    }

    func rename(_ note: Note) {
        present(NoteFormViewController.sheet(title: note.title, heading: "Rename Note") { [store] title in
            note.title = title
            store.viewContext.undoManager?.setActionName("Rename Note")
            try? store.save()
        }, animated: true)
    }

    /// One undo step. Shake or three-finger swipe left brings it back.
    func delete(_ note: Note) {
        store.viewContext.delete(note)
        store.viewContext.undoManager?.setActionName("Delete Note")
        try? store.save()
    }
}
```

Delete from a swipe or a menu needs no confirmation: undo brings it back,
as in Mail and Notes. Confirm only what undo cannot restore (emptying a
trash, deleting an account), with a `UIAlertController` whose destructive
action has the `.destructive` style.

## Swipe actions and context menus

A trailing swipe deletes. A long press opens a menu with the same actions
and more. Tapping a row opens it; here, the rename sheet.

```swift
import UIKit
import NotesCore

extension NotesViewController {
    func swipeActions(at path: IndexPath) -> UISwipeActionsConfiguration? {
        guard let note = note(at: path) else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.delete(note)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemsAt paths: [IndexPath],
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        guard paths.count == 1, let note = note(at: paths[0]) else { return nil }
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in self?.rename(note) },
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self?.delete(note)
                },
            ])
        })
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let note = note(at: indexPath) { rename(note) }
    }
}
```

`swipeActions(at:)` is wired up in the list's `viewDidLoad`, through
`trailingSwipeActionsConfigurationProvider`.

## Snapshot pages

Register a page in `SceneDelegate.snapshotPages` for every tab, sidebar
item and sheet. A page dismisses whatever an earlier page presented.

```swift
private func snapshotPages(_ root: RootSplitViewController) -> [SnapshotPage] {
    [
        SnapshotPage(name: "all") { _ in root.dismiss(animated: false); root.show(.all) },
        SnapshotPage(name: "recent") { _ in root.dismiss(animated: false); root.show(.recent) },
        SnapshotPage(name: "new-note") { _ in
            root.show(.all)
            root.present(NoteFormViewController.sheet(title: "", heading: "New Note") { _ in }, animated: false)
        },
    ]
}
```

Pass `root` in from `scene(_:willConnectTo:options:)`:
`Snapshot.runIfRequested(window: window, pages: snapshotPages(root))`.
