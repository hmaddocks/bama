# Settings window

How to build and structure the Settings window. The skeleton has none: add
it with the first ticket that needs a setting, from the code below.

## Contents

- Structure
- Code
- Tabs
- Rows
- Size and scrolling
- Focus
- Check

## Structure

- A Settings window, opened with Command-comma from the app menu ("Settings…",
  action `showSettings:` on the app delegate). Never a sheet, a page in the
  main window, or a custom-drawn window.
- An `NSTabViewController` with `tabStyle = .toolbar` and one tab per topic.
  macOS draws the tabs as icons in the toolbar. The window title follows the
  tab.
- Each tab is one view controller with an `NSGridView`: labels right-aligned
  in the first column, controls in the second. 520 pt wide.
- Settings apply at once. No Save, Apply, or Cancel button.
- Settings reopens on the tab people last used.
- With a single pane, no tabs: the window title is "<App> Settings".
- Values live in `UserDefaults`, read through one small type in the app
  target (`Preferences`), so every reader agrees on the key and the default.
  Readers that must update live observe `UserDefaults.didChangeNotification`.

## Code

```swift
import Cocoa

/// One tab: its title, symbol, and content.
struct SettingsTab {
    let title: String
    let symbol: String
    let make: () -> NSViewController
}

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static let lastTabKey = "SettingsTab"
    private let tabs = NSTabViewController()

    init(tabs settingsTabs: [SettingsTab]) {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable],
                              backing: .buffered, defer: true)
        window.isRestorable = false
        super.init(window: window)
        tabs.tabStyle = .toolbar
        for tab in settingsTabs {
            let pane = tab.make()
            pane.title = tab.title   // the window title follows the selected tab
            let item = NSTabViewItem(viewController: pane)
            item.label = tab.title
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title)
            tabs.addTabViewItem(item)
        }
        tabs.selectedTabViewItemIndex = min(UserDefaults.standard.integer(forKey: Self.lastTabKey),
                                            settingsTabs.count - 1)
        window.contentViewController = tabs
        window.delegate = self
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(tabs.selectedTabViewItemIndex, forKey: Self.lastTabKey)
    }
}

/// A tab's content: rows of label and control in a grid, sized to fit.
final class SettingsPane: NSViewController {
    private let rows: [(String, NSView)]

    init(rows: [(String, NSView)]) {
        self.rows = rows
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        let grid = NSGridView(views: rows.map { [NSTextField(labelWithString: $0.0), $0.1] })
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.columnSpacing = Space.sm
        grid.rowSpacing = Space.md
        grid.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: Space.xl),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Space.xl),
            grid.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            container.widthAnchor.constraint(equalToConstant: 520),
        ])
        view = container
    }

    /// The tab view controller sizes the window to this, so the window is
    /// as tall as the rows: no empty band, no scroll bar.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutSubtreeIfNeeded()
        preferredContentSize = view.fittingSize
    }
}
```

In the app delegate:

```swift
private lazy var settings = SettingsWindowController(tabs: [
    SettingsTab(title: "General", symbol: "gearshape") {
        let menuBar = NSButton(checkboxWithTitle: "Show the app in the menu bar", target: nil, action: nil)
        return SettingsPane(rows: [("Menu bar:", menuBar)])
    },
])

@IBAction func showSettings(_ sender: Any?) {
    settings.showWindow(nil)
}
```

Register each tab as a snapshot page: show the window, select the tab, and
return `settings.window`.

## Tabs

Add a tab only when a topic has more than about three rows. Two to six tabs
in total. More than six topics (a suite of tools) needs a settings window
with a sidebar instead of tabs. Order:

| Tab | Holds | Symbol |
| --- | --- | --- |
| General | Startup, menu bar and Dock, default behavior | `gearshape` |
| Appearance | Density, and colour only when a milestone asks for it. Light and dark follow the Mac | `paintpalette` |
| Shortcuts | Global shortcut, the list of key commands | `keyboard` |
| One per feature | Options for one big feature (Capture, Sync) | the feature's symbol |
| Permissions | Each system permission with its state | `lock.shield` |
| Advanced | Data folder, export, reset, debug options | `gearshape.2` |

## Rows

- Group rows with a bold section label row, or a separator row between
  groups. Put a short help text under the control in `.secondaryLabelColor`,
  never in the row label.
- Labels say what the setting does, as a statement: "Show Brisk in the menu
  bar", not "Menu bar icon" or "Enable menu bar".
- On and off: a checkbox (`NSButton(checkboxWithTitle:)`) whose title is the
  statement. An `NSSwitch` only for a master setting that turns a whole group
  on.
- Choices: radio buttons (`NSButton(radioButtonWithTitle:)`) for two to five,
  an `NSPopUpButton` beyond that. A segmented control belongs in toolbars and
  inspectors, not in Settings rows.
- Values in the second column line up. Use the system controls, so they do.
- A permission row shows its state ("Allowed", "Not allowed") and one
  button that opens the right pane of System Settings.
- A setting that cannot be used right now is disabled, with the reason
  under it.
- Options that belong to one view (sort, filter, show/hide) live in that
  view or its View menu, not in Settings.
- Do not repeat a system setting (text size, accent, light or dark mode)
  unless the owner asks for it. Offer a button that opens the right System
  Settings pane instead.
- Destructive buttons (Reset, Delete All) go at the bottom of Advanced, with
  `hasDestructiveAction = true` and a confirmation or Undo.

## Size and scrolling

- Each pane sizes to its content, and the tab view controller resizes the
  window to each tab. No scroll bar it does not need.
- A tab taller than 640 pt scrolls. Split it into two tabs before that.

## Focus

The window opens with no field focused: set
`window.initialFirstResponder = nil` and make the window the first
responder. A text field, shortcut recorder, or button never opens with a
focus ring or selected text. The person clicks or presses Tab to start.

## Check

Snapshot mode writes `settings-<tab>-light.png` and `-dark.png` for every
registered tab. In each one:

- No control has a focus ring or selected text.
- No scroll bar, unless the tab is taller than 640 pt.
- The window is as tall as its content: no empty band at the bottom.
- Every label is a statement, and the controls line up.
