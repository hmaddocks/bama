# Design

The app's visual language. The tokens below are implemented in
`__APP_NAME__/DesignTokens.swift`, and in `__APP_NAME__iOS/DesignTokens.swift`
when the app has an iOS target, with the same names and values. Keep all
of them in step.

Native AppKit and UIKit throughout: system fonts, system colours, and
standard controls are the default. Add a token when a
view needs a value the system does not give, and only then.

## Colours

System colours unless a row below says otherwise. On the Mac the accent
follows the accent colour set for the Mac (`.controlAccentColor`). On iOS
it is the window's `tintColor`, system blue.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |

A custom colour is a `DesignTokens.dynamic(light:dark:)` value with a row
here.

## Type

System font throughout, `.monospacedDigitSystemFont` for numbers in
columns. Use the text styles (`NSFont`/`UIFont.preferredFont(forTextStyle:)`)
so the Bold Text setting applies, and on iOS Dynamic Type
(`adjustsFontForContentSizeCategory`).

| Role | Style | Colour (Mac / iOS) |
| --- | --- | --- |
| Body | `.body` | `.labelColor` / `.label` |
| Secondary | `.subheadline` | `.secondaryLabelColor` / `.secondaryLabel` |

## Spacing

`Space` in `DesignTokens.swift`: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`,
`xxl 24`, `section 32`. Mac window content has a 20 pt margin
(`Space.margin`). iOS content uses the system layout margins. Related
controls sit 8 apart, groups 20 to 24, sections 32.

## Components

None yet. Describe each custom component here when a milestone adds one.
