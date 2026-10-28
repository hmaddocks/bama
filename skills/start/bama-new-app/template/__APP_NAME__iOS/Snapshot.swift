import UIKit
import __APP_NAME__Core

/// A screen snapshot mode visits. `show` brings the page up in the window
/// (selects a tab, pushes a screen, presents a sheet).
struct SnapshotPage {
    let name: String
    let show: @MainActor (UIWindow) async -> Void
}

/// Screenshot mode for agents, in the simulator (tools/snap-ios.sh does this):
///   SIMCTL_CHILD_APP_STORE=/tmp/test.sqlite SIMCTL_CHILD_APP_SNAPSHOT=/tmp/shots xcrun simctl launch booted __BUNDLE_ID__
/// writes <page>-<iphone|ipad>-light.png and -dark.png for every registered
/// page, then quits. The simulator shares the Mac's /tmp.
/// APP_SNAPSHOT_PAGES=main limits the pages. APP_SNAPSHOT_ORIENTATION=landscape
/// turns the screen first. Register a page for every tab, screen and sheet a
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
        let only = env["APP_SNAPSHOT_PAGES"].flatMap { $0.isEmpty ? nil : $0 }.map { Set($0.split(separator: ",").map(String.init)) }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let landscape = env["APP_SNAPSHOT_ORIENTATION"] == "landscape"
        Task {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? await Task.sleep(for: .seconds(1.5))
            for mode in ["light", "dark"] {
                window.overrideUserInterfaceStyle = mode == "light" ? .light : .dark
                for page in pages where only?.contains(page.name) ?? true {
                    await page.show(window)
                    try? await Task.sleep(for: .seconds(0.8))
                    capture(window, landscape: landscape, to: "\(dir)/\(page.name)-\(device)-\(mode).png")
                }
            }
            print("SNAPSHOT done \(dir)")
            exit(0)
        }
    }

    /// Draws the window with everything presented on it (sheets, alerts).
    /// For landscape, it lays the root view out at the landscape size and
    /// draws that: iPadOS 26 ignores rotation requests in the simulator's
    /// windowing mode. The iPad is regular width both ways, so only the
    /// bounds change. A page with a sheet open is drawn in portrait, since
    /// the sheet is outside the root view, and its line says so.
    private static func capture(_ window: UIWindow, landscape: Bool, to path: String) {
        var target: UIView = window
        var bounds = window.bounds
        let root = window.rootViewController?.view
        let portrait = root?.frame ?? .zero
        let presenting = window.rootViewController?.presentedViewController != nil
        if landscape, let root, bounds.height > bounds.width, !presenting {
            bounds = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
            root.frame = bounds
            root.layoutIfNeeded()
            target = root
        }
        defer { if target !== window { root?.frame = portrait } }
        let image = UIGraphicsImageRenderer(bounds: bounds).image { context in
            if !target.drawHierarchy(in: bounds, afterScreenUpdates: true) {
                target.layer.render(in: context.cgContext)
            }
        }
        if let data = image.pngData(), (try? data.write(to: URL(fileURLWithPath: path))) != nil {
            print("SNAPSHOT \(path)\(landscape && presenting ? " (portrait: a sheet is open)" : "")")
        } else {
            print("SNAPSHOT failed \(path)")
        }
    }
}
