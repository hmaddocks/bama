# Rebuild an app you like as your own native app.

Agent skills that take a native app from idea to your Dock and Home Screen.<br>
Swift with AppKit on the Mac and UIKit on iPhone and iPad, storing data locally in Core Data.<br>
You never have to open Xcode.

My fork of [BAMA](https://github.com/daveebbelaar/bama).

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![iOS 26+](https://img.shields.io/badge/iOS-26%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white)](#requirements)
[![22 skills](https://img.shields.io/badge/skills-22-5E5CE6?style=flat-square)](#skills)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-D97757?style=flat-square&logo=claude&logoColor=white)](#install)
[![Codex plugin](https://img.shields.io/badge/Codex-plugin-10A37F?style=flat-square)](#install)
[![MIT license](https://img.shields.io/badge/license-MIT-F4C430?style=flat-square)](LICENSE)

**[Why this fork](#why-this-fork) · [Quick start](#quick-start) · [How it works](#how-it-works) · [Skills](#skills) · [Install](#install)**

</div>

## Why this fork

I forked [BAMA](https://github.com/daveebbelaar/bama) from Dave Ebbelaar
and changed three things so it works for me.

1. I fixed its problems. The skills had generic names like `research`,
   `clone` and `performance`, which clashed with other skill packs. Worse,
   the link script replaced any installed skill with the same name without
   asking. I gave every skill a `bama-` prefix, and `link-skills.sh` now
   leaves other packs' skills alone.
2. I switched it from SwiftUI to AppKit and UIKit. SwiftUI never worked
   well for me, and AppKit and UIKit have. A new app
   uses AppKit on the Mac and UIKit on iPhone and iPad, with Core Data for
   storage. SwiftUI stays for contained pieces such as charts. The fork
   also builds iPhone and iPad apps, which BAMA didn't.
3. I moved specs and tickets into my own workflow. The agent writes the
   brief and each milestone's spec in my notes app, and the milestones and
   tickets in my task manager, through their MCP servers. The app's repo
   holds `AGENTS.md`, `CONTEXT.md` (glossary and decisions) and
   `DESIGN.md`, and no plans.

## Quick start

```bash
npx skills@latest add hmaddocks/bama
```

Then ask your agent:

```text
Clone my to-do app as a native app for my Mac and iPhone.
Screenshot every screen, write the user stories, and build milestone 1.
```

If you don't know where to start, type `/bama`. It looks at your project and picks the next skill.

## How it works

<table>
<tr>
<td width="33%" valign="top">

**1. Clone**

Your agent opens the app you like and screenshots every screen. It writes a screen index.

</td>
<td width="33%" valign="top">

**2. Plan**

It writes a brief and a list of milestones. Before each milestone it asks you questions, writes the spec, and breaks it into tickets with checkable acceptance criteria.

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
<tr><td nowrap><a href="skills/start/bama-app-brief/SKILL.md"><samp>bama-app-brief</samp></a></td><td>Turns an idea into a one-page brief, with the app's project and milestones</td></tr>
<tr><td nowrap><a href="skills/start/bama-new-app/SKILL.md"><samp>bama-new-app</samp></a></td><td>An AppKit, UIKit, or both skeleton that builds, tests and snapshots on day one: XcodeGen project, Core Data core package, build script, git. Adds iPhone and iPad to a Mac app later</td></tr>
<tr><td rowspan="4" valign="top"><b>Plan</b></td><td nowrap><a href="skills/plan/bama-research/SKILL.md"><samp>bama-research</samp></a></td><td>Parallel researcher agents: market, users, features, design, macOS APIs</td></tr>
<tr><td nowrap><a href="skills/plan/bama-clone/SKILL.md"><samp>bama-clone</samp></a></td><td>Screenshots every screen of any app with computer use or a browser, writes a screen index</td></tr>
<tr><td nowrap><a href="skills/plan/bama-feature-spec/SKILL.md"><samp>bama-feature-spec</samp></a></td><td>Grills you about one milestone and writes its spec</td></tr>
<tr><td nowrap><a href="skills/plan/bama-user-stories/SKILL.md"><samp>bama-user-stories</samp></a></td><td>Turns a milestone spec into tickets with checkable acceptance criteria</td></tr>
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
<tr><td nowrap><a href="skills/ship/bama-improve-loop/SKILL.md"><samp>bama-improve-loop</samp></a></td><td>Works through a milestone's tickets, one commit each, until the milestone is done</td></tr>
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

- macOS 26 or later. iOS apps need iOS 26 or later
- Xcode 26 or later, with the iOS simulator for iPhone and iPad apps. The scripts use
  Xcode's toolchain even when the Command Line Tools are selected
- XcodeGen: `brew install xcodegen`
- For the planning skills: the task manager and notes app they are written for, with their MCP servers connected
- An agent that supports skills: Claude Code, Codex, Cursor, Gemini CLI
- For `bama-clone` on native apps: computer use (Claude Pro or Max)
- To install on your own iPhone or iPad: an Apple Development certificate
  (a free Apple ID works) and the device connected by cable

## Credits

- Upstream: [BAMA](https://github.com/daveebbelaar/bama) by Dave Ebbelaar.
  This fork keeps its skills, structure and build loop.
- BAMA's idea comes from
  [REA: Reverse Engineer Anything](https://github.com/morluto/rea) by morluto,
  which showed that an agent can reverse engineer any app.
- Skill format and writing rules follow Matt Pocock's
  [skills](https://github.com/mattpocock/skills) and his
  `writing-for-agents` skill.

## License

[MIT](LICENSE)
