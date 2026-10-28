---
name: bama-layout-grid
description: Grid and alignment rules for an AppKit app, with a lint that fails on guessed spacing numbers in constraints, stack views, and insets. Use when building or reviewing a custom page, row, form, or sheet, after every build that touched layout, or when the user says something looks misaligned, crooked, cramped, or unevenly spaced.
---

# Layout grid

Agents guess numbers. A guessed `constant: 13` looks almost right and
makes the whole app feel slightly off. This skill replaces guessing with
one scale and a lint that fails when a number is off it.

The skeleton has both in place: `Space` in `<App>/DesignTokens.swift`, and
`tools/grid-lint.sh`. For an app made before this skill, copy `Space` and
`tools/grid-lint.sh` from the `bama-new-app` skill's template.

## The rules

1. Every constraint constant, stack view spacing, and edge inset comes from
   `Space`: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`, `xxl 24`,
   `section 32`. Raw numbers are 0, 1, 2, or a multiple of 4.
2. Window content has a 20 pt margin (`Space.margin`). Groups pad 16
   (`Space.lg`). Related controls sit 8 apart, groups 20 to 24, sections 32.
3. Each column has one leading edge. Titles, text, and buttons in a column
   start on the same x. Indent on purpose, by a step of the scale.
4. Let containers do the aligning:
   - Labels with controls: `NSGridView`, labels right-aligned in the first
     column (`column(at: 0).xPlacement = .trailing`) and
     `rowAlignment = .firstBaseline`.
   - A row or column of views: `NSStackView` with a `Space` spacing.
   - Text of different sizes in one row: align on `firstBaselineAnchor`.
   - Numbers in a column: `monospacedDigitSystemFont`, trailing aligned.
   - System tables, outline views, source lists, and toolbars align
     themselves. Leave their insets alone.
5. Sheets are 360, 480, or 640 wide. Controls take their height from
   `controlSize`, never from a fixed height constraint.
6. Nested corners are concentric: inner radius = outer radius - inset.
7. Frames set by hand (`frame.origin`, `setFrameOrigin`) do not take part
   in Auto Layout, so nothing lines up with them. Use them only for motion
   and drag images, with `// grid: ok <why>` on the line.
8. Long text truncates (`lineBreakMode`) with its full value in a tooltip.
   Nothing clips.

## Check: lint the code

Run it after every build that touched views:

```bash
tools/grid-lint.sh
# Tasks/TaskRow.swift:14: off grid (10): stack.spacing = 10
# FAIL grid-lint: 1 lines off the grid
```

It reads every Swift file in `<App>/` except `DesignTokens.swift`, and
flags numbers that are not 0, 1, 2, or a multiple of 4 in:

- `constant:`, `equalToConstant:`, `greaterThanOrEqualToConstant:`,
  `lessThanOrEqualToConstant:`
- `spacing`, `columnSpacing`, `rowSpacing` (`=` or `:`)
- `NSEdgeInsets(top:left:bottom:right:)` and `edgeInsets`
- `setFrameOrigin` and `frame.origin`, which it always flags

Fix each line with a `Space` token. A number that must stay (a sheet
width, a measured column from a reference app) gets `// grid: ok <why>`.

Check: `tools/grid-lint.sh` prints `PASS grid-lint`.

## Look at it

The lint catches guessed numbers, not a view that sits on the wrong edge.
After a layout change, open the light and dark snapshots with the Read
tool and check rules 2 to 8 by eye: one leading edge per column, the 20 pt
margin, nothing clipped, no stray gap.

| You see | Usual cause | Fix |
| --- | --- | --- |
| Two leading edges in a column | a centred stack, or one view with its own leading constant | `alignment = .leading` on the stack, one constant on the stack |
| A gap that is not on the scale | `spacing` set on one stack and not another, or `setCustomSpacing` | a `Space` token |
| Content touching the window edge | a missing margin | `edgeInsets` of `Space.margin` on the outer stack |
| Overlapping views | a frame set by hand, or a fixed height | remove it, let Auto Layout size the view |
| Blurry edges | a fractional constant | a whole number from `Space` |

Done when `tools/grid-lint.sh` passes and the snapshots of every page you
touched show one leading edge per column and the 20 pt margin.
