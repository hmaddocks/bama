---
name: bama
description: Build any Mac app. Start here to pick the next skill for a native macOS app.
disable-model-invocation: true
---

# Build any Mac app

Find where the user is on the path below, then call the Skill tool with the
skill for that step. One skill per call.

```text
idea -> bama-research -> bama-clone (optional) -> bama-app-brief -> bama-new-app
     -> bama-mac-design (bama-ios-design for iPhone and iPad) + bama-design-system + bama-app-icon
     -> per milestone: bama-feature-spec -> bama-user-stories -> bama-improve-loop
```

Pick the app's name first (bama-app-brief, step 1), so the Bear notes
(`#apps/<appname>`), the OmniFocus project ("<AppName> App"), and the
folder all share it. Design comes right after the scaffold: tokens from
the first view, and the real icon in every snapshot.

## Find the step

With the app's name, look in this order. The first missing piece is the
step.

1. Bear: the note "<AppName> brief". Missing: `bama-app-brief`.
2. The app's folder has no `project.yml`: `bama-new-app`.
3. OmniFocus, project "<AppName> App": the first incomplete milestone
   action.
   - Its note has no "Spec:" line: `bama-feature-spec`.
   - It has a spec and no ticket sub-actions: `bama-user-stories`.
   - It has open ready-for-agent tickets: `bama-improve-loop`.
   - Only ready-for-human tickets are open: tell the user which ones
     need them.

Report progress per milestone: tickets resolved and open for the current
one, and which milestones are left.

This needs the OmniFocus and Bear MCP servers. If either is missing, say
which.

## Plan

| The user has | Skill |
| --- | --- |
| A vague idea, or asks "what should I build" | `bama-research`, then `bama-app-brief` |
| An app they want to replace or rebuild | `bama-clone` |
| A brief, and a milestone with no spec | `bama-feature-spec` |
| A milestone spec, no tickets | `bama-user-stories` |

## Build

| The user wants to | Skill |
| --- | --- |
| Start a new project | `bama-new-app` |
| Write or fix Swift, AppKit, or Core Data code | `bama-swift` |
| Hook into macOS: hotkeys, menu bar, windows, screen capture, Shortcuts | `bama-os-integrations` |
| Make it fast: hangs, stutter, GPU, video, memory | `bama-performance` |
| Let Claude Code, Codex, or scripts drive the app: a CLI, an MCP server | `bama-agent-cli` |
| Refactor, clean up, or check the code as it grows | `bama-improve-architecture` |

## Design

| The user wants to | Skill |
| --- | --- |
| Decide how a feature works and what it says: names, flow, modals, accessibility | `bama-ux-design` |
| Make it look and feel like a Mac app | `bama-mac-design` |
| Make it look and feel like an iPhone or iPad app | `bama-ios-design` |
| The look of an app they name, or screenshots of one | `bama-design-from-app` |
| An accent or brand color, or one set of colors, radii, and motion for the whole app | `bama-design-system` |
| Fix spacing and alignment, or check the layout on the grid | `bama-layout-grid` |
| An app icon | `bama-app-icon` |

## Ship

| The user wants to | Skill |
| --- | --- |
| Build it and look at every page | `bama-build-and-verify` |
| Tests, a self-test, or an agent that drives the running app | `bama-test-app` |
| Work through a milestone's tickets on its own | `bama-improve-loop` |

## Done when

You named the step, called its skill, and told the user which skill comes
after it.
