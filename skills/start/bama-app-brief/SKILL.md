---
name: bama-app-brief
description: One-page brief for a new app, written to Bear before any code, with the app's OmniFocus project, milestones, and agent docs set up. Use when the user has an app idea, wants to replace an app they pay for, or the bama-research and bama-clone skills are done.
argument-hint: "[idea in a few words]"
---

# App brief

Write the brief as a Bear note, "<AppName> brief", tagged
`#apps/<appname>`. Set up the app's OmniFocus project with one action per
milestone, and write the agent docs into the app's folder
(`<parent>/<AppName>/`; ask for the parent folder, default `~/Developer`).
Every later skill reads the brief. Keep it to one page.

This needs the OmniFocus and Bear MCP servers. If either is missing, say
which, and stop.

## 1. Name and read what exists

Pick the name first: one UpperCamelCase word (`Tasks`, `DailyLog`), not the
name of an app already in `~/Applications`, and a bundle id
`com.<yourname>.<appname>` in lowercase. The folder, the notes, the
OmniFocus project, and the scaffold all use it. The Bear tag is
`#apps/<appname>`, the name in lowercase.

Search Bear for `#apps/<appname>`. If "<AppName> research: <topic>" or
"<AppName>: screens" notes exist, read them first. Skip every question
they already answer.

Check: you have the name, the bundle id, the parent folder, and the list
of notes you read.

## 2. Interview

Ask a few questions at a time. If the user asked you to decide everything,
answer each question yourself from the research, write the choice in the
brief, and note "decided by the agent" next to it.

1. What do you do today, and which app or habit does it replace?
2. What are the three things you do most often? These become the main pages.
3. What data does it hold? Name the nouns: tasks, notes, recipes, invoices.
4. Is there a reference app you like? Then the `bama-clone` skill comes next.
5. Where does it live: a window with a sidebar, a menu bar item, a
   quick-capture panel with a global shortcut, or a mix?
6. Does it need the internet? Default: no.
7. Which three things are out of scope for version one?
8. Any brand or accent color, or an app whose colors and spacing they
   like ("like Things")? The `bama-design-from-app` skill measures it. No
   answer means the Mac's own look and accent color. Controls stay native
   either way.

Check: every question has an answer, from the user, the research, or you
("decided by the agent").

## 3. Cut scope

A personal app has one user. Remove what exists only for other users:
accounts, sharing, teams, sync servers, billing, onboarding, analytics,
upgrade prompts. If the user wants data on two Macs, note "later: iCloud
sync".

Version one is one afternoon of agent time: one window, two to five main
pages, one data model with two to four types. Smart lists that filter one
model (Today, Upcoming, Someday) count as one page.

Check: the brief's "Not in version one" lists everything you cut.

## 4. Plan the milestones

Each milestone ends with an app the user can use for a day. Start from
this list, rename each to fit the app, and drop the ones it does not need:

1. **Core loop**: the one thing the app is for, end to end. Data survives
   a restart.
2. **Organize**: the main structure, sidebar pages, moving items.
3. **Time**: dates, Today and Upcoming, recurrence, reminders.
4. **Speed**: quick-add panel, global shortcut, natural language input,
   keyboard navigation, search, menu commands.
5. **System**: menu bar, Share menu, Shortcuts, notifications, CLI.
6. **Polish**: drag and drop, context menus, empty states, icon, settings.

Give each one a one-line scope.

Check: every main job in the brief belongs to a milestone.

## 5. Write the brief

Create the Bear note "<AppName> brief" with `ifNotExists`, tagged
`#apps/<appname>`:

```markdown
One sentence: what it is and who it is for.

## Replaces
<app or habit>

## Main jobs
1. ...
2. ...
3. ...

## Data
- <Type>: <fields>

## Shape
<sidebar window / menu bar extra / quick panel>, macOS 26 or later.
Local data. Works offline. No accounts.

## System hooks
<global shortcut, menu bar, Share menu, Shortcuts, CLI, or "none">

## Reference
<app name, or "none">

## Look
<the Mac's own look with an accent color (name it, or "system"), or "colors and spacing like <app>", and why>

## Milestones
1. <name>: <one-line scope>

## Not in version one
- ...

## Design plan
(filled in by bama-mac-design)
```

Check: the note exists and has every section.

## 6. Set up OmniFocus and the repo

Create the app's project and its triage tag group. The script is safe to
run again:

```bash
"${CLAUDE_SKILL_DIR}/scripts/omnifocus-setup.sh" <AppName>
```

It prints the project's id. Add one action per milestone to "<AppName>
App" with the OmniFocus MCP server, in order, each tagged `Mac`, with its
one-line scope as the note.

Write the agent docs into the app's folder:

```bash
"${CLAUDE_SKILL_DIR}/scripts/repo-docs.sh" <AppName> <parent>/<AppName>
```

It writes `AGENTS.md` (and a `CLAUDE.md` link), `CONTEXT.md`,
`docs/agents/`, and `tools/omnifocus-setup.sh`. Add the brief's data
nouns to the glossary in `CONTEXT.md`, one row each.

Check: the OmniFocus project has one action per milestone, the tag group
"<AppName> triage" has five tags, and the folder has `AGENTS.md`,
`CONTEXT.md`, and `docs/agents/`.

## 7. Hand off

Call the Skill tool with `bama-feature-spec` for the first milestone, or
with `bama-new-app` if the user wants to see a window first.

Done when the Bear note "<AppName> brief" has every section and fits on
one page, the OmniFocus project has every milestone as an action, and the
app's folder has its agent docs with the data nouns in the glossary.
