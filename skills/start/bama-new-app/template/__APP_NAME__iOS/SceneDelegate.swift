import UIKit
import __APP_NAME__Core

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private(set) var store: Store?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        self.window = window
        // Test runs never open the real store, not even to refuse.
        if (SelfTest.requested || Snapshot.requested) && !Store.isOverridden {
            print("refused: set APP_STORE to a file in /tmp for --selftest and APP_SNAPSHOT")
            exit(1)
        }
        do {
            store = try Store(url: Store.defaultURL(appName: "__APP_NAME__"))
        } catch {
            NSLog("__APP_NAME__: could not open the store: \(error)")
            window.rootViewController = StoreFailureViewController(error: error)
            window.makeKeyAndVisible()
            return
        }
        guard let store else { return }
        window.rootViewController = RootViewController(store: store)
        window.makeKeyAndVisible()

        SeedData.insertIfRequested(into: store)
        SelfTest.runIfRequested(store: store, window: window)
        Snapshot.runIfRequested(window: window, pages: snapshotPages)
    }

    /// Every screen snapshot mode visits. Add one for each tab, sidebar
    /// item, and sheet a ticket adds.
    private var snapshotPages: [SnapshotPage] {
        [SnapshotPage(name: "main") { _ in }]
    }
}

/// The skeleton's only screen: an empty view on the system background. The
/// first milestone's tickets replace it, usually with a split view controller
/// (bama-swift uikit-recipes.md). Undo and shake-to-undo act on the store.
final class RootViewController: UIViewController {
    let store: Store

    init(store: Store) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override var undoManager: UndoManager? { store.viewContext.undoManager }
}

/// Shown when the store cannot open, instead of crashing at launch.
final class StoreFailureViewController: UIViewController {
    private let error: Error

    init(error: Error) {
        self.error = error
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        var config = UIContentUnavailableConfiguration.empty()
        config.image = UIImage(systemName: "exclamationmark.triangle")
        config.text = "Could Not Open Your Data"
        config.secondaryText = error.localizedDescription
        contentUnavailableConfiguration = config
    }
}
