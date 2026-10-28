---
name: bama-ios-design
description: Design rules that make a UIKit app look and feel native on iPhone and iPad with iOS 26 and later, from navigation and size classes to sheets, touch targets, Dynamic Type, swipe actions, context menus, and the iPad keyboard. Use when building or reviewing any iOS screen, tab bar, sidebar, list, or sheet, or when the user asks for a more native or better designed iPhone or iPad app.
---

# iPhone and iPad design

Apple already designed your app. Pick the right UIKit parts, arrange them,
and stay out of their way. Use the system first. Add custom design only
where the system has nothing, and only after asking: name the UIKit
default and what departing from it costs.

- Copyable UIKit code (the split view with a compact tab bar, lists, form
  sheets, swipe actions, context menus): `bama-swift`'s uikit-recipes.md.
- Apple's current text on one topic, when a rule here is not enough:
  `"${CLAUDE_SKILL_DIR}/../bama-mac-design/scripts/hig.sh" <topic>` (for
  example `tab-bars`, `sheets`). Read the iOS and iPadOS sections.
- Apple's eight design principles, the review lens for every screen: the
  top of `bama-mac-design`. They hold on every platform.
- App-wide tokens (colors, radii, motion): call the Skill tool with
  `bama-design-system`. How a feature works and what it says: call the
  Skill tool with `bama-ux-design`. Spacing and the lint: call the Skill
  tool with `bama-layout-grid`.

A screen that also exists on the Mac is designed again for touch, not
copied. It shares the model and the words, not the layout.

## Before you write views

Write these under `## Design plan (iOS)` in the Bear note "<App> brief":

1. **Navigation**: the top-level pages (tabs on iPhone, sidebar items on
   iPad), at most five, in the Mac sidebar's order when there is a Mac app.
2. **Each page's stack**: what a tap on a row pushes, and how deep it goes.
3. **Actions**: each one's place: the navigation bar, a swipe, a context
   menu, or the bottom toolbar.
4. **Empty states**: what each page shows before there is data.

## Navigation

- iPhone: a tab bar for the top-level pages, a navigation stack inside
  each tab. The tab bar stays visible as people move through a tab. Only a
  modal covers it.
- iPad: a sidebar and the selected page, in a `UISplitViewController`. The
  same pages as the iPhone tabs, in the same order, with the same symbols.
  A narrow iPad window falls back to the tab bar.
- Use the split view with a compact tab bar (uikit-recipes.md) when the
  sidebar holds more than the tabs, like Cashflow's account summary. When
  the pages are only tabs, a `UITabBarController` with `mode = .tabSidebar`
  does both by itself.
- An iPhone always gets the iPhone layout, even a large one in landscape:
  set `traitOverrides.horizontalSizeClass = .compact` on the root for
  `.phone`.
- Tabs navigate; they never act. Never hide or disable a tab: an empty
  page says why it is empty. Labels are one word, with SF Symbols.
- Lay out by size class and the view's width, never by device model.
  Rotation and iPad window resizing change both at any time.

## Bars and Liquid Glass

- Navigation bars, tab bars, toolbars and sheets get Liquid Glass on their
  own. Delete any custom background behind them. Content (rows, cards) gets
  none.
- The navigation bar title names the page. Root pages of a tab can use a
  large title; pushed pages use the standard one.
- Bar buttons are SF Symbols with an accessibility label, or one word. At
  most one prominent button (`style = .prominent`), for the action that
  completes the screen, like Save.
- Actions on the page go in the navigation bar's trailing side: Add (`+`)
  first. Several actions on a selection go in a bottom toolbar
  (`setToolbarItems`), not crowded into the navigation bar.

## Lists

- Lists are `UICollectionView` lists: `.insetGrouped` for settings and
  forms, `.plain` or `.insetGrouped` for content, `.sidebar` for the iPad
  sidebar. Cells use `UIListContentConfiguration`, so text styles, insets
  and selection match the system.
- A tap opens the row. A trailing swipe holds the destructive action, a
  leading swipe the positive one (mark done, pin). Every swipe action also
  lives in the row's context menu.
- A long press opens a context menu with every action on the row,
  destructive ones last and marked `.destructive`.
- Pull to refresh only for data that comes from somewhere else. A local
  store needs none.
- An empty list shows `UIContentUnavailableConfiguration`: a symbol, what
  the page is for, and the first action.

## Sheets and alerts

- A sheet is a task: add, edit, pick. Cancel on the leading side, the
  completing action (Save, Add, Done) on the trailing side.
- `.formSheet` on iPad. On iPhone, `.medium()` and `.large()` detents for
  short forms. Once people type, block swipe to dismiss
  (`isModalInPresentation`) instead of losing their text.
- One sheet at a time. A step inside a sheet pushes onto its navigation
  controller; it does not open another sheet.
- Confirm only what undo cannot restore. Use an action sheet
  (`UIAlertController`, `.actionSheet`) with the destructive button marked
  `.destructive`. On iPad it is a popover and needs a `sourceItem`.
- Undo for every delete: shake, the three-finger swipe, and Command-Z
  (uikit-recipes.md, "Undo").

## Touch, type, and color

- Every tap target is at least 44 by 44 pt, even when the symbol is
  smaller. Keep 8 pt between targets.
- Text uses text styles (`.preferredFont(forTextStyle:)`) with
  `adjustsFontForContentSizeCategory = true`. Body is 17 pt at the default
  size. Never fixed point sizes.
- Layouts grow with Dynamic Type: labels wrap (`numberOfLines = 0`),
  stacks turn vertical at accessibility sizes
  (`traitCollection.preferredContentSizeCategory.isAccessibilityCategory`),
  and nothing truncates that people need to read.
- Long text on iPad sits in `readableContentGuide`, not edge to edge.
- Colors are semantic: `.label`, `.secondaryLabel`,
  `.systemBackground` for plain screens, `.systemGroupedBackground` behind
  inset-grouped lists. One accent color, set as the window's `tintColor`.
  Status color always comes with an icon or a word.
- SF Symbols for every icon. Respect Reduce Motion and Reduce
  Transparency. Haptics only to confirm an action that has no visible
  result.

## iPad keyboard and pointer

- Every command a Mac app has in its menu bar has a keyboard shortcut on
  iPad: Command-N to add, Command-F to search, Delete on a selected row,
  Command-Z to undo. Add them as `UIKeyCommand`s on the view controller
  that handles them, or to the iPadOS menu bar with `buildMenu(with:)` in
  the app delegate. Holding Command shows them.
- Arrow keys move the selection in lists and the sidebar
  (`selectionFollowsFocus` and `allowsFocus` on the collection view).
- Pointer hover works on standard controls. Custom controls get a
  `UIPointerInteraction`.

## Review set

Run `tools/snap-ios.sh` and read every image: each page and sheet on the
iPhone in portrait and the iPad in landscape, light and dark. Then check
one pass at the largest accessibility size:

```bash
xcrun simctl ui "iPhone 17" content_size accessibility-extra-extra-extra-large
tools/snap-ios.sh
xcrun simctl ui "iPhone 17" content_size large
```

Look for clipped or truncated text, targets smaller than 44 pt, a tab bar
on iPad or a sidebar on iPhone, custom backgrounds behind bars, and an
empty page with no explanation.

Done when every rule above holds on the light and dark snapshots of every
page and sheet on both devices, at the default and the largest text size,
or has a comment saying why not.
