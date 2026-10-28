# Design

The app's visual language. The tokens below are implemented in
`__APP_NAME__/DesignTokens.swift`; keep the two in step.

Native AppKit throughout: system fonts, system colours, and standard
controls are the default for a task-focused Mac app. Add a token when a
view needs a value the system does not give, and only then.

## Colours

System colours unless a row below says otherwise. The accent follows the
accent colour set for the Mac (`.controlAccentColor`).

| Token | Light | Dark | Use |
| --- | --- | --- | --- |

A custom colour is a `DesignTokens.dynamic(light:dark:)` value with a row
here.

## Type

System font throughout (`NSFont.systemFont`, `.monospacedDigitSystemFont`
for numbers in columns). Use the text styles (`NSFont.preferredFont(forTextStyle:)`)
so Dynamic Type sizes and the Bold Text setting apply.

| Role | Style | Colour |
| --- | --- | --- |
| Body | `.body` | `.labelColor` |
| Secondary | `.subheadline` | `.secondaryLabelColor` |

## Spacing

`Space` in `DesignTokens.swift`: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`,
`xxl 24`, `section 32`. Window content has a 20 pt margin (`Space.margin`).
Related controls sit 8 apart, groups 20 to 24, sections 32.

## Components

None yet. Describe each custom component here when a milestone adds one.
