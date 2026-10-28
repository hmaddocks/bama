import Cocoa
import __APP_NAME__Core

/// Owns the main window from MainMenu.xib. The first milestone's tickets
/// put real content here: usually an NSSplitViewController (see bama-swift).
@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    let store: Store

    init(window: NSWindow, store: Store) {
        self.store = store
        super.init(window: window)
        window.delegate = self
        contentViewController = EmptyViewController()
        // Setting the content resizes the window to the content's own size,
        // which is tiny for a split view. Size it, then let a saved frame win.
        window.setContentSize(NSSize(width: 900, height: 600))
        window.setFrameAutosaveName("MainWindow")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Undo and Redo in the Edit menu act on the store.
    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        store.viewContext.undoManager
    }
}

/// The skeleton's only view: an empty pane on the window background.
final class EmptyViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
    }
}
