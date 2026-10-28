---
name: design-from-app
description: Measure the look of an app the user likes (sizes, spacing, type, colors) from its screenshots, write the numbers into the app's design tokens, and compare pixel by pixel until a screen matches. Use when the user names an app whose look they want, shares screenshots of one, or says "make it look like X".
argument-hint: "<app name or screenshot paths>"
---

# Design from app

Look at an app, measure it, and put its numbers into this app's design
tokens. Controls stay native: the reference app lends its colors, type
sizes, and spacing, not its custom parts. Where the reference uses a
custom control, use the native control that does the same job.

Guessing gets close. Measuring gets it right. Two scripts do the
measuring, next to this skill:

- `scripts/measure.swift`: sizes, positions, text heights, and colors from
  a screenshot.
- `scripts/compare.swift`: a side-by-side, a diff, and the share of pixels
  that differ.

Run them with `swift "${CLAUDE_SKILL_DIR}/scripts/measure.swift" ...`.
All coordinates are points (pixels / 2 for a Retina capture).

## 1. Get the screenshots

Ask for screenshots, or take them with the `clone` skill. You need:

- The window only, at 2x, no desktop. Save them in `design/reference/`.
- One screen with the most on it (a sidebar, a list, a toolbar), plus
  close-ups of menus, dialogs, and dark mode if they matter.
- The window size: `measure.swift info shot.png`.

Check: `info` prints the window size in points, and every screenshot uses
the same scale.

## 2. List what to measure

Name every token the screenshots show: window size, sidebar width, row
height and pitch, left edges, gaps, text sizes per role, surface colors,
text colors, the accent, and the selection color. Note each custom control
and the native control that replaces it.

Check: every visible element on the main screenshot maps to a token or to
a native control.

## 3. Measure

Give every token a number, not an estimate. The recipes and the traps are
in [measuring.md](measuring.md). In short:

| To find | Command |
| --- | --- |
| Sidebar width, panes | `hline shot.png <y in an empty area>` |
| Row positions and pitch | `rows shot.png <x0> <x1> [y0 y1]` |
| Left edges, gaps | `cols shot.png <y0> <y1> [x0 x1]` |
| Selection pill, dividers | `vline` and `hline` through it, `--tolerance 4` |
| Text and icon colors | `ink shot.png x y w h` |
| Surface colors | `palette shot.png x y w h` |
| A close look | `crop shot.png x y w h out.png 4` |

Most apps on the Mac use the system font. Start there, and name another
font only when the letters differ (a, g, t, digits). Match icons with SF
Symbols.

Check: every token from step 2 has a number from a command.

## 4. Write the tokens and build one screen

Call the Skill tool with `design-system` and write the measured numbers
into the app's tokens. Then build the main screenshot's screen with native
controls and those tokens, with the same data and the same window size.

Check: a snapshot of that screen has the same size in pixels as the
reference.

## 5. Compare until it matches

```bash
swift "${CLAUDE_SKILL_DIR}/scripts/compare.swift" design/reference/main.png /tmp/<App>-shots/<page>-light.png /tmp/<App>-compare
swift "${CLAUDE_SKILL_DIR}/scripts/compare.swift" ... /tmp/<App>-compare-sidebar 0 0 220 300
```

Open `side-by-side.png` and `diff.png` with the Read tool. Then measure
the same rows, edges, and words in both images, and fix the tokens, not
the views. Order: window size, text sizes, columns and left edges, row
heights, colors.

Native controls draw themselves, so a pixel match is not the goal where a
native control replaced a custom one. Match the layout and colors around
it.

Check: every row and left edge is within 1.5 pt of the reference, and
every measured color matches its token.

Done when every token from step 2 has a measured number in the app's
tokens, every custom control in the reference has a named native
replacement, and the reference screen passes step 5.
