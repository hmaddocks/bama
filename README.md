<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/banner-light.png">
  <img alt="BAMA: Build Any Mac App" src="docs/assets/banner-light.png" width="860">
</picture>

### See an app you like. Rebuild it as your own native app.

Agent skills that take a native app from idea to your Dock and Home Screen.<br>
Swift, AppKit on the Mac, UIKit on iPhone and iPad, and Core Data. Local data. No Xcode GUI needed.

A fork of [daveebbelaar/bama](https://github.com/daveebbelaar/bama) for
AppKit and UIKit apps, planned in OmniFocus and Bear. An app is for the
Mac, iPhone and iPad, or both, sharing one core package.

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![iOS 26+](https://img.shields.io/badge/iOS-26%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white)](#requirements)
[![21 skills](https://img.shields.io/badge/skills-22-5E5CE6?style=flat-square)](#skills)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-D97757?style=flat-square&logo=claude&logoColor=white)](#install)
[![Codex plugin](https://img.shields.io/badge/Codex-plugin-10A37F?style=flat-square)](#install)
[![MIT license](https://img.shields.io/badge/license-MIT-F4C430?style=flat-square)](LICENSE)

**[Quick start](#quick-start) · [How it works](#how-it-works) · [Skills](#skills) · [Install](#install)**

</div>

## Quick start

```bash
npx skills@latest add hmaddocks/bama
```

Then ask your agent:

```text
Clone my to-do app as a native app for my Mac and iPhone.
Screenshot every screen, write the user stories, and build milestone 1.
```

Not sure where to start? Type `/bama`. It looks at your project and picks the next skill.

## How it works

<table>
<tr>
<td width="33%" valign="top">

**1. Clone**

Your agent opens the app you like and screenshots every screen. It writes a screen index.

</td>
<td width="33%" valign="top">

**2. Plan**

It writes a brief in Bear and the milestones in OmniFocus. Before each milestone it asks you questions, writes the spec in Bear, and breaks it into OmniFocus tickets with checkable acceptance criteria.

</td>
<td width="33%" valign="top">

**3. Build**

It builds one ticket per commit. Before each commit it snapshots every page in light and dark mode (on the Mac, an iPhone and an iPad) and runs the tests.

</td>
</tr>
</table>

## Skills

<table>
<tr><th>Stage</th><th>Skill</th><th>What it does</th></tr>
<tr><td rowspan="3" valign="top"><b>Start</b></td><td nowrap><a href="skills/start/bama/SKILL.md"><samp>bama</samp></a></td><td>Router: finds where you are and calls the right skill</td></tr>
<tr><td nowrap><a href="skills/start/bama-app-brief/SKILL.md"><samp>bama-app-brief</samp></a></td><td>Turns an idea into a one-page brief in Bear, with the app's OmniFocus project and milestones</td></tr>
<tr><td nowrap><a href="skills/start/bama-new-app/SKILL.md"><samp>bama-new-app</samp></a></td><td>An AppKit, UIKit, or both skeleton that builds, tests and snapshots on day one: XcodeGen project, Core Data core package, build script, git. Adds iPhone and iPad to a Mac app later</td></tr>
<tr><td rowspan="4" valign="top"><b>Plan</b></td><td nowrap><a href="skills/plan/bama-research/SKILL.md"><samp>bama-research</samp></a></td><td>Parallel researcher agents: market, users, features, design, macOS APIs</td></tr>
<tr><td nowrap><a href="skills/plan/bama-clone/SKILL.md"><samp>bama-clone</samp></a></td><td>Screenshots every screen of any app with computer use or a browser, writes a screen index</td></tr>
<tr><td nowrap><a href="skills/plan/bama-feature-spec/SKILL.md"><samp>bama-feature-spec</samp></a></td><td>Grills you about one milestone and writes its spec as a Bear note</td></tr>
<tr><td nowrap><a href="skills/plan/bama-user-stories/SKILL.md"><samp>bama-user-stories</samp></a></td><td>Turns a milestone spec into OmniFocus tickets with checkable acceptance criteria</td></tr>
<tr><td rowspan="5" valign="top"><b>Code</b></td><td nowrap><a href="skills/code/bama-swift/SKILL.md"><samp>bama-swift</samp></a></td><td>Swift 6 concurrency, AppKit and UIKit recipes, Core Data, menus and undo, hosting a SwiftUI piece, iCloud sync, compiler errors</td></tr>
<tr><td nowrap><a href="skills/code/bama-os-integrations/SKILL.md"><samp>bama-os-integrations</samp></a></td><td>Global hotkeys, menu bar, floating panels, window control, screen capture, Shortcuts, URL schemes, CLI, permissions</td></tr>
<tr><td nowrap><a href="skills/code/bama-performance/SKILL.md"><samp>bama-performance</samp></a></td><td>Measure, then fix: main thread, GPU compositing, images, Instruments from the command line</td></tr>
<tr><td nowrap><a href="skills/code/bama-improve-architecture/SKILL.md"><samp>bama-improve-architecture</samp></a></td><td>Finds hot spots as the app grows and refactors one step per commit, with behavior proven unchanged</td></tr>
<tr><td nowrap><a href="skills/code/bama-agent-cli/SKILL.md"><samp>bama-agent-cli</samp></a></td><td>Optional: a command line and MCP server, so Claude Code, Codex, and scripts can drive your app</td></tr>
<tr><td rowspan="7" valign="top"><b>Design</b></td><td nowrap><a href="skills/design/bama-ux-design/SKILL.md"><samp>bama-ux-design</samp></a></td><td>Names, flow, where each feature opens (inline, popover, sheet, window), words, and accessibility, before code</td></tr>
<tr><td nowrap><a href="skills/design/bama-mac-design/SKILL.md"><samp>bama-mac-design</samp></a></td><td>Liquid Glass, layout, toolbars, menus, keyboard, type, dark mode</td></tr>
<tr><td nowrap><a href="skills/design/bama-ios-design/SKILL.md"><samp>bama-ios-design</samp></a></td><td>iPhone and iPad: navigation, size classes, sheets, touch, Dynamic Type, iPad keyboard</td></tr>
<tr><td nowrap><a href="skills/design/bama-design-system/SKILL.md"><samp>bama-design-system</samp></a></td><td>Design tokens in DesignTokens.swift and one DESIGN.md that says which to use when, with contrast checked</td></tr>
<tr><td nowrap><a href="skills/design/bama-layout-grid/SKILL.md"><samp>bama-layout-grid</samp></a></td><td>A 4 pt grid for AppKit and UIKit layouts, and a lint that fails on guessed numbers in constraints, stack views and insets</td></tr>
<tr><td nowrap><a href="skills/design/bama-design-from-app/SKILL.md"><samp>bama-design-from-app</samp></a></td><td>Rebuilds the look of an app you like from its screenshots: measures sizes, type, and colors, then compares pixel by pixel until it matches</td></tr>
<tr><td nowrap><a href="skills/design/bama-app-icon/SKILL.md"><samp>bama-app-icon</samp></a></td><td>A Liquid Glass icon written as an Icon Composer file, checked in every look</td></tr>
<tr><td rowspan="3" valign="top"><b>Ship</b></td><td nowrap><a href="skills/ship/bama-build-and-verify/SKILL.md"><samp>bama-build-and-verify</samp></a></td><td>Build, install, snapshot every page in light and dark on the Mac or in the simulator, look at them</td></tr>
<tr><td nowrap><a href="skills/ship/bama-test-app/SKILL.md"><samp>bama-test-app</samp></a></td><td>Swift Testing in the core package, an in-app self-test with menu checks, a debug bridge an agent can drive</td></tr>
<tr><td nowrap><a href="skills/ship/bama-improve-loop/SKILL.md"><samp>bama-improve-loop</samp></a></td><td>Works through a milestone's OmniFocus tickets, one commit each, until the milestone is done</td></tr>
</table>

## Install

Pick one route per agent. Two routes install every skill twice.

<details open>
<summary><b>Claude Code</b></summary>

```text
/plugin marketplace add hmaddocks/bama
/plugin install bama@bama
```

</details>

<details>
<summary><b>Codex</b></summary>

```bash
codex plugin marketplace add hmaddocks/bama
codex plugin add bama@bama
```

</details>

<details>
<summary><b>Any other agent</b> (Cursor, Gemini CLI, Copilot, and more)</summary>

Uses [skills.sh](https://skills.sh). Install all skills, or one with `--skill`.

```bash
npx skills@latest add hmaddocks/bama -a <agent>
npx skills@latest add hmaddocks/bama --skill=bama-clone
```

</details>

<details>
<summary><b>By hand</b></summary>

```bash
git clone https://github.com/hmaddocks/bama.git
bama/scripts/link-skills.sh       # links every skill into ~/.claude/skills and ~/.agents/skills
```

</details>

## Requirements

- macOS 26 or later; the iOS apps run on iOS 26 or later
- Xcode 26 or later, with the iOS simulator for iPhone and iPad apps (you never have to open it; the scripts use its toolchain
  even when the Command Line Tools are selected)
- XcodeGen: `brew install xcodegen`
- OmniFocus and Bear, with their MCP servers connected, for the planning skills
- An agent that supports skills: Claude Code, Codex, Cursor, Gemini CLI
- For `bama-clone` on native apps: computer use (Claude Pro or Max)
- To install on your own iPhone or iPad: an Apple Development certificate
  (a free Apple ID works) and the device connected by cable

## Credits

- Upstream: [BAMA](https://github.com/daveebbelaar/bama) by Dave Ebbelaar.
  This fork keeps its skills and structure.
- The idea and the "any" promise come from
  [REA: Reverse Engineer Anything](https://github.com/morluto/rea) by morluto.
  REA showed that an agent can reverse engineer any app. BAMA takes that idea to the Mac.
- Skill format and writing rules follow Matt Pocock's
  [skills](https://github.com/mattpocock/skills) and his
  `writing-for-agents` skill.

## License

[MIT](LICENSE)
