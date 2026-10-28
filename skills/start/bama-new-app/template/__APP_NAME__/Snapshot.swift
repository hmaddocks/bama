import AppKit
import IOKit.pwr_mgt
import __APP_NAME__Core

/// A screen snapshot mode visits. `show` brings the page up (selects a
/// sidebar item, opens a sheet) and returns the window to capture.
struct SnapshotPage {
    let name: String
    let show: @MainActor () async -> NSWindow?
}

/// Screenshot mode for agents.
///   APP_STORE=/tmp/test.sqlite APP_SNAPSHOT=/tmp/shots ~/Applications/__APP_NAME__.app/Contents/MacOS/__APP_NAME__
/// writes <page>-light.png and <page>-dark.png for every registered page,
/// then quits. APP_SNAPSHOT_PAGES=main,settings limits the pages.
/// Register a page for every sidebar item, sheet, panel and Settings tab a
/// ticket adds (AppDelegate.snapshotPages), or the loop cannot see it.
@MainActor
enum Snapshot {
    static var requested: Bool {
        !(ProcessInfo.processInfo.environment["APP_SNAPSHOT"] ?? "").isEmpty
    }

    static func runIfRequested(pages: [SnapshotPage]) {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["APP_SNAPSHOT"], !dir.isEmpty else { return }
        // Snapshots never run against the real store.
        guard Store.isOverridden else {
            print("SNAPSHOT refused: set APP_STORE to a file in /tmp")
            NSApp.terminate(nil)
            return
        }
        let only = env["APP_SNAPSHOT_PAGES"].map { Set($0.split(separator: ",").map(String.init)) }
        Task {
            // A sleeping display gives screencapture nothing. Declaring user
            // activity wakes it; the assertion keeps it on until the run quits.
            var activity: IOPMAssertionID = 0
            IOPMAssertionDeclareUserActivity("Snapshots" as CFString, kIOPMUserActiveLocal, &activity)
            var awake: IOPMAssertionID = 0
            IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                        IOPMAssertionLevel(kIOPMAssertionLevelOn), "Snapshots" as CFString, &awake)
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? await Task.sleep(for: .seconds(1.5))
            // Started from a terminal, the app is not active, and an inactive
            // window draws grey traffic lights and dim selection. Activation
            // arrives a moment later, so wait for it before the first capture.
            activate()
            for _ in 0..<30 where !NSApp.isActive { try? await Task.sleep(for: .seconds(0.1)) }
            for mode in ["light", "dark"] {
                NSApp.appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
                for page in pages where only?.contains(page.name) ?? true {
                    let window = await page.show()
                    try? await Task.sleep(for: .seconds(0.8))
                    capture(window, to: "\(dir)/\(page.name)-\(mode).png")
                }
            }
            print("SNAPSHOT done \(dir)")
            // An open sheet refuses terminate, and the run would wait forever.
            for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
            NSApp.terminate(nil)
        }
    }

    /// `NSApp.activate()` only asks to become active, and a terminal that
    /// keeps focus says no. Snapshots need the real active look.
    private static func activate() {
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Captures the real window with screencapture, so materials, sidebars
    /// and glass look as on screen. That needs Screen Recording permission
    /// for the app that started this one (your terminal, or Claude).
    /// Without it, falls back to drawing the view hierarchy, which leaves
    /// sidebars and glass blank.
    private static func capture(_ window: NSWindow?, to path: String) {
        // Another app can hide this one while snapshots run (computer use hides
        // apps it does not control). Hidden windows cannot be captured.
        if NSApp.isHidden { NSApp.unhideWithoutActivation() }
        guard let window else {
            print("SNAPSHOT no window for \(path)")
            return
        }
        // Active, like a window someone is using: real accent colours and focus rings.
        activate()
        window.makeKeyAndOrderFront(nil)
        let note = window.isKeyWindow ? "" : " (not key: inactive look, capture again)"
        try? FileManager.default.removeItem(atPath: path)
        // The first capture of a run sometimes misses the window. Try three times.
        for _ in 1...3 {
            let shot = Process()
            shot.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            shot.arguments = ["-x", "-o", "-l", String(window.windowNumber), path]
            try? shot.run()
            shot.waitUntilExit()
            if FileManager.default.fileExists(atPath: path) {
                print("SNAPSHOT \(path)\(note)")
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        guard let view = window.contentView?.superview ?? window.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
            print("SNAPSHOT \(path) (fallback: no Screen Recording permission, sidebars and glass are blank)")
        }
    }
}
