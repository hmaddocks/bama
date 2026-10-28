import Cocoa
import __APP_NAME__Core

// Not `@main`: with `@main`, `NSApplicationDelegate`'s synthesized entry
// point loads MainMenu.xib with File's Owner set to `NSApplication` itself,
// not this class, so any outlet wired from the xib fails at runtime
// ("Failed to connect (window) outlet from (NSApplication) to (NSWindow)").
// `main.swift`'s plain `NSApplicationMain` call uses the classic pattern:
// the xib creates this class as a top-level object and makes it the delegate.
//
// `@objc(AppDelegate)`: a Swift class is registered with the Objective-C
// runtime under its module-qualified name (`__APP_NAME__.AppDelegate`), not
// the bare name the xib's `customClass` uses. Without it the nib loader logs
// "Unknown class 'AppDelegate'" and silently uses a plain NSObject.
@objc(AppDelegate)
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!
    private(set) var store: Store!
    private var windowController: MainWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            store = try Store(url: Store.defaultURL(appName: "__APP_NAME__"))
        } catch {
            NSLog("__APP_NAME__: could not open the store: \(error)")
            NSApp.presentError(error)
            NSApp.terminate(nil)
            return
        }
        windowController = MainWindowController(window: window, store: store)
        windowController.showWindow(nil)
        // Started from a terminal, the process is not a foreground app yet.
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
