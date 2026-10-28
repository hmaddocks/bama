import CoreData
import Foundation

/// The app's Core Data store. Entities live in `__APP_NAME__Core.xcdatamodeld`,
/// next to this file. After an entity change that is not a lightweight
/// migration, add a model version instead of editing the current one.
@MainActor
public final class Store {
    public enum LoadError: Error, CustomStringConvertible {
        case modelNotFound

        public var description: String {
            "Could not find the compiled __APP_NAME__Core.momd in Bundle.module."
        }
    }

    /// Loaded from `Bundle.module`, not `Bundle.main`: once this package is
    /// embedded in the app, `Bundle.main` is the app and has no model.
    nonisolated(unsafe) public static let model: NSManagedObjectModel = {
        guard let url = Bundle.module.url(forResource: "__APP_NAME__Core", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url)
        else { fatalError(LoadError.modelNotFound.description) }
        return model
    }()

    public let container: NSPersistentContainer

    /// The main-actor context views read and edit. Its undo manager backs
    /// Edit > Undo.
    public var viewContext: NSManagedObjectContext { container.viewContext }

    /// Opens the store at `url`, or an in-memory store when `url` is nil
    /// (store-level tests only).
    public init(url: URL?) throws {
        container = NSPersistentContainer(name: "__APP_NAME__Core", managedObjectModel: Self.model)
        let description = NSPersistentStoreDescription(url: url ?? URL(fileURLWithPath: "/dev/null"))
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.undoManager = UndoManager()
    }

    /// Saves the view context when it has changes.
    public func save() throws {
        if viewContext.hasChanges { try viewContext.save() }
    }

    /// Where the store lives. `APP_STORE` overrides it (tests, snapshots,
    /// the self-test). Debug builds use `<App>-dev.sqlite`, so developing
    /// never touches the store the user relies on.
    public nonisolated static func defaultURL(appName: String) -> URL {
        if let path = ProcessInfo.processInfo.environment["APP_STORE"], !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        let dir = URL.applicationSupportDirectory.appending(path: appName, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        #if DEBUG
        return dir.appending(path: "\(appName)-dev.sqlite")
        #else
        return dir.appending(path: "\(appName).sqlite")
        #endif
    }

    /// True when `APP_STORE` points the app at another store.
    public nonisolated static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }
}
