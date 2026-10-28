import Foundation
import __APP_NAME__Core

/// Sample data for snapshots: APP_SEED=1 with APP_STORE in /tmp fills an
/// empty store. Seed only what a person can create in the app, or the
/// snapshots show features no one can use. The skeleton has nothing to seed.
@MainActor
enum SeedData {
    static func insertIfRequested(into store: Store) {
        guard ProcessInfo.processInfo.environment["APP_SEED"] == "1" else { return }
        guard Store.isOverridden else {
            print("APP_SEED ignored: APP_STORE must be a file in /tmp")
            return
        }
        // Insert sample objects here, then save:
        try? store.save()
    }
}
