# Toolbars

Toolbar layout for a macOS 26 AppKit window. Placement changed between 26.0
and 26.2: snapshot the toolbar after each OS update. The code is in
patterns.md, "Toolbar that follows the columns".

## Contents

- Areas
- Columns
- Toggles
- Glass groups
- Labels
- Title and search
- Review
- Sources

## Areas

| Area | What goes there | AppKit |
|---|---|---|
| Leading | Sidebar toggle, back and forward, title and subtitle | `.toggleSidebar`, `window.title`, `window.subtitle` |
| Center | Common controls. They fold into the overflow menu as the window narrows | items between the tracking separators |
| Trailing | Inspector toggle, search, the one primary action. Visible at every width | `.toggleInspector`, `NSSearchToolbarItem`, `visibilityPriority = .high` |

- At most three groups in the whole toolbar. Only frequent commands get an item.
- Every toolbar item also has a menu bar command and shortcut. People can hide the toolbar.
- The system adds the overflow menu. Never build your own to make items fit.
- No Settings button. Settings opens from the app menu with Command-comma.
- An app people keep open for hours, or with many items, lets people customize
  the toolbar: `allowsUserCustomization = true` and
  `autosavesConfiguration = true`, with `toolbarAllowedItemIdentifiers` listing
  every item. Leading items stay fixed.
- A More menu (`ellipsis`, an `NSMenuToolbarItem`) at the trailing edge may
  hold extra actions. The main actions never hide in it.
- Back and Close use the standard symbols (`chevron.backward`, `xmark`), never
  the words.

## Columns

With an `NSSplitViewController`, tracking separators split the toolbar at
the column dividers, and an item sits over the column between its
separators.

- Sidebar column: no items of your own. `.toggleSidebar`, then
  `.sidebarTrackingSeparator`.
- Content column: actions that make or order rows (New, Sort), and search
  over the list. `.flexibleSpace` first pushes them to the column's trailing
  edge.
- Inspector column: `.inspectorTrackingSeparator`, `.flexibleSpace`, then
  `.toggleInspector`. The inspector is an
  `NSSplitViewItem(inspectorWithViewController:)` with its own toolbar area.
- A three-pane window (sidebar, list, detail) adds an
  `NSTrackingSeparatorToolbarItem` bound to the second divider for the detail
  column's actions (Share, Flag, Delete).
- Check: snapshot with the sidebar collapsed and the inspector closed. Every
  item stays over its column, in the same order.

## Toggles

- Sidebar: the system `.toggleSidebar` item. Never draw a second one. Leave it
  out only when the sidebar never hides.
- View > Show Sidebar (Control-Command-S) is a menu item with the action
  `toggleSidebar:` sent to the first responder. Add it to `MainMenu.xib`.
- Inspector: the system `.toggleInspector` item, after `.flexibleSpace`.
  View > Show Inspector (Control-Command-I) sends `toggleInspector:`. Put
  that shortcut in the item's `toolTip`. No second inspector command
  elsewhere.
- View > Show Toolbar (`toggleToolbarShown:`, Option-Command-T) and
  Customize Toolbar… (`runToolbarCustomizationPalette:`) go in the View menu
  too.

## Glass groups

On macOS 26 toolbar items float on Liquid Glass, and neighbors share one capsule.

- `.space` splits groups with different jobs. `.flexibleSpace` pushes items
  apart. `NSToolbarItemGroup` keeps a set together.
- No backgrounds, borders, or dimming behind the toolbar. The scroll edge
  effect keeps it legible and turns more opaque over dense content.
- Monochrome SF Symbols. Tint only to carry meaning.

## Labels

- A symbol first. Text only when no symbol fits ("Edit"). Always set
  `label` and `paletteLabel` too, so the title shows in the overflow menu,
  in Icon and Text mode, in Customize Toolbar, and to VoiceOver.
- Every item has a `toolTip`: what it does, starting with a verb, then the
  shortcut ("Create a note (Command-N)"). Not the item's name again.
- A primary action (Done, Send) is one item, trailing, alone, prominent
  (`style = .prominent`). Most main windows have none. "New" is not a
  primary action.

## Title and search

- `window.title` names the content in under 15 characters, never the app.
  `window.subtitle` holds a count or a date.
- Every page has a subtitle, or none does. A subtitle that comes and goes
  changes the toolbar height and makes the window jump.
- Search over the list: an `NSSearchToolbarItem` in the content column. It
  collapses to a button when the window is narrow, and expands on click.
- Window-wide search sits at the trailing edge, over an open inspector, as
  in Mail and Notes.
- Command-F focuses the field (Edit > Find > Find…, calling
  `searchItem.beginSearchInteraction()`), and so does Option-Command-F,
  Apple's standard "jump to the search field". Escape clears it. The
  subtitle shows the result count.
- A big app with many sections (Music) gets a Search item in the sidebar.
  Selecting it shows a full results page and focuses its field.
- Recent searches and the no-results view: patterns.md, "Search with recent
  searches".
- Check the toolbar at the window's minimum width with the inspector open
  and closed: items that do not fit must go to the overflow menu, not
  disappear.

## Review

The toolbar fails when it has two sidebar or inspector toggles, items over
the wrong column, items that move when a column collapses, more than three
groups, an item without a `toolTip` or `label`, an action missing from the
menu bar, a Settings button, tint as decoration, or a row of buttons drawn
in the content area in place of an `NSToolbar`.

## Sources

- HIG: [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars), [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views), [Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields), [The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- WWDC25-310 Build an AppKit app with the new design: https://developer.apple.com/videos/play/wwdc2025/310/
- WWDC25-356 Get to know the new design system: https://developer.apple.com/videos/play/wwdc2025/356/
- AppKit: [NSToolbar](https://developer.apple.com/documentation/appkit/nstoolbar), [NSTrackingSeparatorToolbarItem](https://developer.apple.com/documentation/appkit/nstrackingseparatortoolbaritem), [NSSearchToolbarItem](https://developer.apple.com/documentation/appkit/nssearchtoolbaritem), [NSSplitViewItem](https://developer.apple.com/documentation/appkit/nssplitviewitem)
- Field test: Brisk commit f9f264b, and placement snapshots on macOS 26.5
