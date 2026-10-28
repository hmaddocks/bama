# Accessibility audit

How to check step 7 of [SKILL.md](SKILL.md) on a running build, and the
AppKit calls that fix what it finds. Standard controls do most of this
on their own. Custom controls need the work.

## Contents

- Run the audit
- Keyboard
- VoiceOver
- Custom controls
- Color and contrast
- Motion and transparency
- Text size

## Run the audit

1. Build and open the app: `./build.sh --open`.
2. Open Accessibility Inspector: `open -a "Accessibility Inspector"` (it
   ships with Xcode). Pick the app as the target, open the Audit tab, and
   run the audit on each new view.
3. Turn on keyboard navigation: System Settings > Keyboard > Keyboard
   navigation. Run the whole flow with Tab, arrows, Return, Escape, and
   Space.
4. Turn on VoiceOver with Command-F5. Move with Control-Option and the
   arrow keys. Run the flow again, listening.
5. In System Settings > Accessibility > Display, turn on Increase
   Contrast, Reduce Motion, and Reduce Transparency one at a time. Look at
   each new view in light and dark mode.

Done when the audit shows no issues for the new views and both runs
finish the flow without the mouse.

## Keyboard

- Every step of the flow is reachable with the keyboard, in reading order.
- The default button responds to Return, Cancel to Escape.
- A new item gets focus so people can type at once.

```swift
extension NotesViewController {
    /// After inserting a note: select its row and start editing its title.
    func focusNewRow(_ row: Int) {
        table.selectRowIndexes([row], byExtendingSelection: false)
        table.scrollRowToVisible(row)
        view.window?.makeFirstResponder(table)
        table.editColumn(0, row: row, with: nil, select: true)
    }
}
```

## VoiceOver

- The label matches the words on screen. An icon-only button keeps its
  title as the VoiceOver label; the tooltip describes what it does.
- A row reads as one element, with its actions available from the
  VoiceOver actions menu.
- Decorative images stay silent.

```swift
@MainActor
func configureAccessibility(add: NSButton, row: NSTableCellView, hero: NSImageView,
                            title: String, due: String, complete: @escaping () -> Void) {
    add.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
    add.imagePosition = .imageOnly
    add.setAccessibilityLabel("New Task")            // VoiceOver reads "New Task"
    add.toolTip = "Add a task to this list (\u{2318}N)"

    row.setAccessibilityElement(true)               // the row reads as one element
    row.setAccessibilityLabel("\(title), due \(due)")
    row.setAccessibilityCustomActions([NSAccessibilityCustomAction(name: "Complete") { complete(); return true }])

    hero.setAccessibilityElement(false)             // decorative
}
```

- Section titles are headings, so VoiceOver can jump between them:
  `label.setAccessibilityRole(NSAccessibility.Role(rawValue: "AXHeading"))`
  (AppKit has no named constant for it).
- When content changes without a click (a sync finishes, a filter empties
  the list), post an announcement:
  `NSAccessibility.post(element: window, notification: .announcementRequested, userInfo: [.announcement: "No tasks left", .priority: NSAccessibilityPriorityLevel.high.rawValue])`.
- A chart gets a one-line summary as its label ("Spending rose 12% in
  October").
- Voice Control says what people see: the visible label and the
  accessibility label are the same words.
- No view that hides itself on a timer is the only way to act. An Undo
  toast also has Edit > Undo, Command-Z.

## Custom controls

Every custom control answers four questions for VoiceOver (WWDC26-220):
what it is (label), what it is set to (value), what people can do
(actions), and what changed (feedback). A control that only works with a
drag also offers actions, so Switch Control and Voice Control reach it.

```swift
/// A drawn dial that VoiceOver, Switch Control, and Voice Control can use.
final class VolumeDial: NSView {
    var level = 0.5 { didSet { needsDisplay = true } }   // 0...1
    private var lastAnnounced = Date.distantPast

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        path.appendArc(withCenter: center, radius: min(bounds.width, bounds.height) / 2 - 4,
                       startAngle: 90, endAngle: 90 - 360 * level, clockwise: true)
        path.lineWidth = 6
        NSColor.controlAccentColor.setStroke()
        path.stroke()
    }

    override func mouseDragged(with event: NSEvent) {
        level = min(1, max(0, level + event.deltaY / -400))
        announce()
    }

    // What it is, what it is set to, what people can do.
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .slider }
    override func accessibilityLabel() -> String? { "Volume" }
    override func accessibilityValue() -> Any? { level.formatted(.percent.precision(.fractionLength(0))) }
    override func accessibilityPerformIncrement() -> Bool { level = min(1, level + 0.1); return true }
    override func accessibilityPerformDecrement() -> Bool { level = max(0, level - 0.1); return true }
    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        [NSAccessibilityCustomAction(name: "Mute") { [weak self] in self?.level = 0; return true }]
    }

    /// During a drag, speak the value at most every 0.3 s: what changed.
    private func announce() {
        guard Date.now.timeIntervalSince(lastAnnounced) >= 0.3, let window else { return }
        lastAnnounced = .now
        NSAccessibility.post(element: window, notification: .announcementRequested,
                             userInfo: [.announcement: level.formatted(.percent.precision(.fractionLength(0)))])
    }
}
```

A two-axis control (a color square, a position pad) gets four named
actions, "Move Up", "Move Down", "Move Left", "Move Right", with a fixed
step that stops at the edges.

## Color and contrast

- Status color always comes with an icon or a word.
- Body text contrast is at least 4.5 to 1 against its background, in light
  and dark mode. Aim for 7 to 1 for small text in custom colors.
- Honor Differentiate Without Color and Increase Contrast in custom views.

```swift
@MainActor
func statusImage() -> NSImage? {
    let noColorOnly = NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
    return NSImage(systemSymbolName: noColorOnly ? "exclamationmark.circle.fill" : "circle.fill",
                   accessibilityDescription: "Overdue")
}
// NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast tells a custom
// view to strengthen its borders and text.
```

## Motion and transparency

Replace slides, springs, and parallax with a fade when Reduce Motion is on.
Never animate a blur or a change in depth (scale toward the viewer) under
Reduce Motion, and make springs tighter. Never make people wait for an
animation: it can be interrupted. Give custom glass a solid fallback when
Reduce Transparency is on.

```swift
@MainActor
func show(_ view: NSView) {
    if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        view.animator().alphaValue = 1                    // fade only
    } else {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            view.animator().alphaValue = 1
            view.animator().frame.origin.x -= 8           // grid: ok slide in
        }
    }
}
// Custom glass or blur gets a solid fallback when
// NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency is true.
// Observe NSWorkspace.accessibilityDisplayOptionsDidChangeNotification on
// NSWorkspace.shared.notificationCenter to update while the app runs.
```

## Text size

- macOS body text is 13 pt and nothing is under 10 pt. Use text styles
  (`NSFont.preferredFont(forTextStyle: .body)`, `.callout`, `.caption1`),
  not fixed sizes.
- Truncated text shows its full value in a tooltip.

```swift
@MainActor
func configureTruncation(_ field: NSTextField) {
    field.lineBreakMode = .byTruncatingTail
    field.maximumNumberOfLines = 1
    field.toolTip = field.stringValue      // set again when the text changes
}
```

macOS has no Dynamic Type, but people must be able to enlarge text to
200%. An app people read in (notes, articles, mail) adds View > Bigger,
Smaller, and Actual Size, and scales its reading text from one setting:

```swift
/// View > Bigger, Smaller, Actual Size. Reading views read `scale` and
/// refresh on `TextScale.didChange`.
@MainActor
enum TextScale {
    static let didChange = Notification.Name("TextScaleDidChange")
    static var scale: Double {
        get { UserDefaults.standard.object(forKey: "textScale") as? Double ?? 1 }
        set {
            UserDefaults.standard.set(min(2, max(0.8, newValue)), forKey: "textScale")
            NotificationCenter.default.post(name: didChange, object: nil)
        }
    }
    static var readingFont: NSFont { .systemFont(ofSize: 13 * scale) }   // grid: ok 13 pt body, scaled
}

extension AppDelegate {
    @IBAction func makeTextBigger(_ sender: Any?) { TextScale.scale += 0.1 }
    @IBAction func makeTextSmaller(_ sender: Any?) { TextScale.scale -= 0.1 }
    @IBAction func makeTextActualSize(_ sender: Any?) { TextScale.scale = 1 }
}
// Menu items in View: "Bigger" (Command-+), "Smaller" (Command--),
// "Actual Size" (Command-0), with these actions.
```
