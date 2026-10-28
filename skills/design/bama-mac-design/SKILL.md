---
name: bama-mac-design
description: Design rules that make an AppKit app look and feel like a native Mac app on macOS 26 and later, from Apple's eight design principles to Liquid Glass, layout, toolbars, menus, search, keyboard, type, color, and dark mode. Use when building or reviewing any window, sidebar, toolbar, menu, panel, or settings screen, or when the user asks for a more native, Apple-like, or better designed app.
---

# Mac design

Apple already designed your app. Pick the right system parts, arrange them,
and stay out of their way. Use the system first. Add custom design only
where the system has nothing, and only after asking: name the AppKit
default and what departing from it costs.

- The full checklist with sources: [design-rules.md](design-rules.md).
  Use it for reviews.
- Copyable AppKit code: [patterns.md](patterns.md). The split view, table,
  sheets, and undo are in `bama-swift`'s appkit-recipes.md.
- The Settings window: [settings.md](settings.md).
- Toolbars: which item goes where, per column: [toolbars.md](toolbars.md).
- The menu bar, context menus, and the Dock menu: [menus.md](menus.md).
- Apple's current text on one topic, when a rule here is not enough:
  `"${CLAUDE_SKILL_DIR}/scripts/hig.sh" <topic>` (for example `toolbars`,
  `sheets`). It prints the HIG page as plain text.
- App-wide tokens (colors, radii, motion): call the Skill tool with
  `bama-design-system`.
- How a feature works and what it says (names, flow, modals, errors,
  accessibility): call the Skill tool with `bama-ux-design`.
- Spacing, alignment, and the checks that catch misalignment: call the
  Skill tool with `bama-layout-grid`.
- The colors, type, and spacing of an app the user names: call the Skill
  tool with `bama-design-from-app`.

## Apple's eight principles

Use them as the review lens for every screen (HIG Design principles, 2026):

1. **Purpose**: each feature costs people time, attention, and trust. Cut what does not earn it.
2. **Agency**: people choose their path. Undo forgives mistakes. No forced tours.
3. **Responsibility**: ask for permissions at first use, keep data private, guard AI output.
4. **Familiarity**: things that look the same work the same. Standard parts, standard symbols.
5. **Flexibility**: keyboard, pointer, and resizing all work. People can customize what they use daily.
6. **Simplicity**: simple is not minimal. Hierarchy comes from order, space, and contrast.
7. **Craft**: instant response, smooth scrolling, aligned edges, layouts that survive resizing.
8. **Delight**: the sum of the other seven, aimed at one feeling. Never decoration added at the end.

Every screen answers: Where am I? What can I do? Where can I go?

## Before you write views

Write these four under `## Design plan` in the Bear note "<App> brief":

1. **Archetype**: sidebar window, single-window document, menu bar extra, or
   quick-capture panel. Most personal apps are a sidebar window plus one
   quick-capture entry point. A menu bar utility is "menu bar extra +
   panels + Settings window": the toolbar and sidebar rules then apply to
   the Settings window only.
2. **Information architecture**: sidebar pages, at most two levels.
3. **Command map**: every action, its menu, its shortcut.
4. **Empty states**: what each page shows before there is data.
5. **Feeling**: the one feeling the app aims for (calm, quick, confident).
   Motion, words, and color all reinforce it.

## Entry points first

A Mac app is used through its small entry points: a global shortcut, the
menu bar, a quick panel, drag and drop, the Share menu. Design those first.
A to-do app lives in its quick-add panel.

- Quick capture: one floating panel, one input, opened by a global shortcut,
  closed by Escape or Return.
- **Optimistic UI**: on Return, close and show the result at once. Save in the
  background. Offer Undo, not a spinner.

## Layout

- `NSSplitViewController`: sidebar, content, detail. Global actions in the
  toolbar. No sidebar when navigation is one level.
- Selection details in an inspector split view item or the detail column.
- The UI frames the user's content. Ask what the least UI is that lets it
  stand out.
- Progressive disclosure: an empty page shows one centred message (what the
  page is for) with the first action as a button. Filters appear once there is content.
- Keep the top 50 pt free for dragging the window.
- Spacing from `Space`, on a 4 pt grid: 20 pt window margins, 8 pt
  between related controls, 20 pt between groups. `controlSize` for dense
  areas, never hard-coded heights.

## Liquid Glass

- Glass is for the navigation and control layer: toolbars, sidebars,
  floating buttons, popovers. Content (rows, cards, documents) gets none.
- Never glass on glass. Group neighboring custom glass in one
  `NSGlassEffectContainerView`.
- Standard components get glass on their own. Delete custom backgrounds
  behind bars and sheets.
- `NSGlassEffectView` only for a custom floating control. Tint only to carry
  meaning. Interactive glass (the bounce on click) only on controls, and
  sparingly.
- Custom chrome dims with the window: check `isEmphasized` on a row view,
  or the window's `isKeyWindow` (patterns.md, "Custom selection that follows
  the window").

## Toolbars and menus

- Each toolbar item sits over the column it acts on: nothing of your own
  over the sidebar, New and Sort over the list, actions on the selection
  over the detail, the inspector toggle over the inspector. Full rules and
  a checked example: [toolbars.md](toolbars.md).
- At most three toolbar groups, split with `.space`. Monochrome SF
  Symbols, each with a `label` and a `toolTip`. At most one prominent action,
  only for a completing action like Done or Send. Most main windows have
  none.
- View menu items for `toggleSidebar:`, `toggleToolbarShown:`, and (with an
  inspector) `toggleInspector:`, so the View menu can show and hide each
  part.
- Every toolbar button and feature also lives in the menu bar with a
  shortcut (`MainMenu.xib`, or `NSMenuItem` in code). Apple's menu order
  and labels: [menus.md](menus.md).
- Menu icons only on key actions, all or none in a group.
- Standard shortcuts keep their meaning: Command-C, V, X, Z, W, Q, N, comma.
- Disable menu items that do not apply; keep them visible. Validate them in
  `validateMenuItem(_:)` (`bama-swift`, "Menu commands").
- Window titles name the content ("Today"), not the app.

## Windows open calm

- Nothing is focused when a window or sheet opens: no focus ring, no
  blinking cursor, no selected text. Put `.noInitialFocus()` on every
  window and sheet. The one exception is a window whose only job is
  typing, like a search or quick-add panel: it focuses its field.
- A sidebar list may hold focus at launch. It shows as a selected row, not
  a ring, and the arrow keys work at once.
- A sheet, popover, or Settings tab grows to fit its content
  (`.fitsContent()`). It scrolls only when the content is taller than
  the screen allows, about 640 pt.
- System scroll bars. The "Show scroll bars" setting decides when they
  show. Do not restyle them.

## Keyboard first

- Every frequent action has a shortcut, and every shortcut shows feedback
  in the same frame.
- Return is the default action, Escape cancels, Delete removes, Space
  previews, arrows move.
- New items get focus (`window.makeFirstResponder(field)`) so the user can
  type at once.
- Teach shortcuts in menus, tooltips, and a list in Settings.

## Color, type, dark mode

- Text is `.labelColor`, `.secondaryLabelColor`, `.tertiaryLabelColor`.
  System backgrounds. No
  fixed white, black, or gray in chrome.
- One accent color. Status color always comes with an icon or a word.
- macOS text styles: body 13 pt, nothing under 10 pt. Never iOS sizes.
  Headline is bold 13 pt, the same size as Body. Full table:
  design-rules.md rule 29.
- Dark mode is its own palette with more distance between tones. Check
  both in every snapshot.
- Accent-colored text uses a deep shade in light mode and a light shade in
  dark mode. Text and symbols on an accent fill use
  `.alternateSelectedControlTextColor`, never a fixed white (white fails on
  yellow and green accents).
- Hover and press never lower contrast. Text over user content
  (screenshots, video) sits on a dark scrim or capsule.
- SF Symbols for every icon (`NSImage(systemSymbolName:accessibilityDescription:)`).

## Interaction

- A context menu (`menu` on the view, built in `menuNeedsUpdate(_:)`) on
  everything a user can act on. It hides items that do
  not apply and shows no shortcuts. Hover states on custom controls. Mac
  controls are 22 to 28 pt tall, not 44.
- Drag and drop in and out with `NSPasteboardWriting` and
  `NSFilePromiseProvider`. A drag to Finder makes a real file. An
  `NSSharingServicePicker` where sharing fits.
- Relaunch brings back the windows, the selection, and the scroll position
  (frame autosave, and saved ids in `UserDefaults`). Quit never asks unless
  typed work would be lost.
- Undo for every destructive or bulk action, in Settings too. A one-click
  trash button needs Undo in place.
- A Settings window, opened with Command-comma: tabs, one grid of rows per
  tab, sized to its content. Structure and rows: [settings.md](settings.md).
- Respect Reduce Motion and Reduce Transparency. Label icon-only buttons.

## When to customize

Custom chrome is fine when it makes the app clearly better at its one job,
like a quick-add field or a calendar grid. Write why in a code comment, and
match the system: concentric radii, system fonts, system spacing.

## Review set

Snapshot every surface in light and dark: each page, the menu bar menu,
each panel and overlay (launcher, toasts, cards), editors, and each
Settings tab (register each one as a snapshot page). Look for focus
rings, selected text, scroll bars with nothing to scroll, and empty bands
under short content. Capture each window as the key window: a snapshot of
an inactive window (gray traffic lights, dim toggles) or with flattened
glass does not count as reviewed. Views that pause while covered show a
placeholder; that one is expected.

Done when every rule in [design-rules.md](design-rules.md) holds on the
light and dark snapshots of every surface, or has a comment saying why not.
