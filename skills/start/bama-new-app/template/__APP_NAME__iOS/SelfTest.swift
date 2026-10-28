import UIKit
import __APP_NAME__Core

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1. In the
/// simulator, pass --selftest as a launch argument:
///   SIMCTL_CHILD_APP_STORE=/tmp/__APP_NAME__-self.sqlite xcrun simctl launch --console booted __BUNDLE_ID__ --selftest
/// Add a check for every ticket whose model or storage behavior a unit test
/// in __APP_NAME__Core cannot reach.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(store: Store, window: UIWindow) {
        guard requested else { return }
        // Print each line at once, so a crash keeps the lines before it.
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            exit(1)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.5))

            check("the store opens", !store.container.persistentStoreCoordinator.persistentStores.isEmpty)
            check("the store has an undo manager", store.viewContext.undoManager != nil)
            check("the window is visible", window.isKeyWindow && window.rootViewController != nil)

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            exit(failures == 0 ? 0 : 1)
        }
    }

    static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }
}
