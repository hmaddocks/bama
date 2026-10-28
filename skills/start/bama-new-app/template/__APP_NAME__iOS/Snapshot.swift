import UIKit
import __APP_NAME__Core

/// A screen snapshot mode visits. `show` brings the page up in the window
/// (selects a tab, pushes a screen, presents a sheet).
struct SnapshotPage {
    let name: String
    let show: @MainActor (UIWindow) async -> Void
}

/// Screenshot mode for agents, in the simulator:
///   SIMCTL_CHILD_APP_STORE=/tmp/test.sqlite SIMCTL_CHILD_APP_SNAPSHOT=/tmp/shots xcrun simctl launch booted __BUNDLE_ID__
/// writes <page>-light.png and <page>-dark.png for every registered page,
/// then quits. The simulator shares the Mac's /tmp. APP_SNAPSHOT_PAGES=main
/// limits the pages. Register a page for every tab, screen and sheet a
/// ticket adds (SceneDelegate.snapshotPages), or the loop cannot see it.
@MainActor
enum Snapshot {
    static var requested: Bool {
        !(ProcessInfo.processInfo.environment["APP_SNAPSHOT"] ?? "").isEmpty
    }

    static func runIfRequested(window: UIWindow, pages: [SnapshotPage]) {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["APP_SNAPSHOT"], !dir.isEmpty else { return }
        // Snapshots never run against the real store.
        guard Store.isOverridden else {
            print("SNAPSHOT refused: set APP_STORE to a file in /tmp")
            exit(1)
        }
        setvbuf(stdout, nil, _IOLBF, 0)
        let only = env["APP_SNAPSHOT_PAGES"].map { Set($0.split(separator: ",").map(String.init)) }
        Task {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? await Task.sleep(for: .seconds(1))
            for mode in ["light", "dark"] {
                window.overrideUserInterfaceStyle = mode == "light" ? .light : .dark
                for page in pages where only?.contains(page.name) ?? true {
                    await page.show(window)
                    try? await Task.sleep(for: .seconds(0.8))
                    capture(window, to: "\(dir)/\(page.name)-\(mode).png")
                }
            }
            print("SNAPSHOT done \(dir)")
            exit(0)
        }
    }

    /// Draws the window with everything presented on it (sheets, alerts).
    private static func capture(_ window: UIWindow, to path: String) {
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        if let data = image.pngData(), (try? data.write(to: URL(fileURLWithPath: path))) != nil {
            print("SNAPSHOT \(path)")
        } else {
            print("SNAPSHOT failed \(path)")
        }
    }
}
