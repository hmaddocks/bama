---
name: bama-design-system
description: Design tokens for an AppKit and UIKit app, the Cashflow way: DesignTokens.swift in each target and one DESIGN.md at the repo root that says which token to use when. Use when the user wants a brand or accent colour, when an app has more than a few screens, when screens drift apart or colours and spacing feel inconsistent, or when the user asks for a style guide or design tokens.
---

# Design system

A design system is a short list of **tokens** in code and one page that
says which token to use when. Every view uses tokens or system colours,
never raw values. Then a change in one place changes the whole app, and an
agent can review a screen against one page.

The skeleton has both files: `<App>/DesignTokens.swift` and `DESIGN.md`.
An app with an iOS target also has `<App>iOS/DesignTokens.swift`: the same
token names and values as `UIColor`, so one `DESIGN.md` covers both. Add
every token to both files in the same commit. They start almost empty on
purpose. Start from `bama-mac-design`: tokens
cover only what the system does not, and a token is added when a view first
needs it. The app keeps Apple's look and native controls. To take the
colours, type, and spacing of an app the user names, call the Skill tool
with `bama-design-from-app`.

There is no accent picker or theme store. On the Mac, the accent is the
one the person set for their Mac (`.controlAccentColor`). iOS has no
personal accent: the app's accent is the window's `tintColor`, system blue
unless the brief names one. A picker is built only when a
milestone asks for it, as a departure from the default.

## 1. Read the look

Read `## Look` in the Bear note "<App> brief".

- No colour named: keep the system accent. Selection, buttons, and focus
  rings use `.controlAccentColor` and the system's selection colours, so
  they follow the person's choice and the accessibility settings.
- A brand colour: add one token, `brand`, with a light and a dark value.
  Use it sparingly: the app icon, an empty state, one hero element in the
  content. Keep it off controls, selection, and focus rings, which stay
  system. [HIG Color, Branding]

Check: you can say which colours the app uses beyond system colours, and
why each one exists.

## 2. Collect

New app with no views yet? Skip this step.

Existing app: read every view. List each raw value you find: hex colours,
`NSColor(red:...)`, `UIColor(red:...)`, opacities, corner radii, constraint constants, fonts
with a fixed size, animation durations. Group them. Most apps have 3 to 5
of each where 1 or 2 are meant.

Check: every raw value is in a group, and each group has the one or two
values it should have.

## 3. Write the tokens

Everything goes in `DesignTokens.swift`, one `// MARK:` section per group,
each added when the app first needs it:

| Group | Holds |
| --- | --- |
| Colours | `DesignTokens.dynamic(light: "#...", dark: "#...")` values: surfaces, borders, text for custom surfaces, status colours (`income`, `expense`, `warning`) |
| Fonts | text roles beyond the system styles, such as `amount` (monospaced digits) |
| `Space` | the 4 pt spacing scale (already there; see `bama-layout-grid`) |
| Radius | `sm 6` chips, `md 10` cards, `lg 16` floating panels |
| Motion | durations for the few custom animations, all skipped under Reduce Motion |

```swift
// In enum DesignTokens, under // MARK: Colours

/// Positive amounts. The light value is darkened from #059669, which
/// only reaches 3.7:1 on the window background; this clears 4.5:1.
static let income = dynamic(light: "#047857", dark: "#34d399")
```

In `<App>iOS/DesignTokens.swift` the token is the same line: its
`dynamic(light:dark:)` returns a `UIColor`.

Every colour that text sits on, or that is text, has a comment with its
contrast, and clears 4.5:1 (3:1 for text 18 pt and larger). Fix the light
value, the dark value, or both; never ship a token that fails. [HIG Color,
WCAG AA]

Check: every raw value from step 2 has a token or a system colour that
replaces it.

## 4. Write DESIGN.md

`DESIGN.md` mirrors the code: a Colours table (token, light, dark, use), a
Type table (role, style, colour), the Spacing scale, and a Components list
that describes each custom component in a line or two. Keep it under 100
lines. Rules that transfer to most apps:

- Never hard-code a colour in a view. Use a token or a system colour.
- Never redefine or copy a semantic colour (`.separatorColor` as text, a
  label colour as a fill). Their values change per release.
- Every custom colour has a light and a dark value. Check it in both
  appearances and with Increase Contrast. [HIG Color]
- Accent-coloured text uses a deep shade in light mode and a light shade in
  dark mode. Text on an accent fill uses
  `.alternateSelectedControlTextColor` on the Mac, never a fixed white.
- System fonts and text styles. A custom font only for headings, with a
  bold weight for the Bold Text setting.
- Style a control with its own properties (`bezelStyle`, `controlSize`,
  `contentTintColor`; `UIButton.Configuration` on iOS). Never rebuild a control from shapes: it loses the
  keyboard, focus, and VoiceOver.
- Inner corners are concentric: inner radius = outer radius - inset.
- Animations are short, skipped under Reduce Motion
  (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`), and never
  run on a view's first layout. Search results and switchers do not
  animate: speed wins.
- Hover never moves a selection. Only a click or a key does.
- One primary button per window or sheet (`keyEquivalent = "\r"`).

Check: every token in each `DesignTokens.swift` has a row or a line in
`DESIGN.md`, and nothing in `DESIGN.md` is missing from either file.

## 5. Migrate

Replace raw values screen by screen, one commit per screen. After each,
build and snapshot (`bama-build-and-verify` skill). The screen looks the
same or better, never worse.

Check: the snapshots of each migrated screen, light and dark, match or
improve on the ones before.

Done when this finds no hits outside `DesignTokens.swift`:

```bash
grep -rnE '(NS|UI)Color\((red|hex|srgbRed|calibratedRed|white):|#[0-9a-fA-F]{6}"|cornerRadius = [0-9]|duration = [0-9]|systemFont\(ofSize: [0-9]' <App>/ <App>iOS/ \
  | grep -v DesignTokens.swift
```

(hex strings in data and comments are fine; drop `<App>iOS/` for a
Mac-only app), and `DESIGN.md` and every `DesignTokens.swift` list the
same tokens.
