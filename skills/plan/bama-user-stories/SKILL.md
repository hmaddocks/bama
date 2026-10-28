---
name: bama-user-stories
description: Tickets with checkable acceptance criteria for one milestone of an app, written as OmniFocus sub-actions from the milestone's Bear spec. Use after bama-feature-spec, or when the user asks for tickets, user stories, or "what do we build first" for a milestone.
argument-hint: "[milestone name]"
---

# User stories

Screens show what an app looks like. Stories say what a person does with
it. You build and test stories, not screens. Each story becomes a ticket:
an OmniFocus sub-action under the milestone action.

This needs the OmniFocus and Bear MCP servers. If either is missing, say
which, and stop.

## 1. Read

Take the milestone the user named, or the first incomplete milestone
action in "<App> App" that has a spec and no tickets. Read:

- its spec, "<App> spec: <milestone>", and its Q&A note "<App>: <milestone>"
- `CONTEXT.md` in the app's repo, for the names to use
- "<App>: screens", where it exists, for the reference screenshots

Check: you have the spec's numbered user stories in front of you.

## 2. Write the tickets

One ticket per action a person takes: "Rename a project from its context
menu", not "Manage projects". Number them T1, T2 in build order, so
tickets that others depend on come first. Name each sub-action
"T<n> <action>".

The ticket's note:

```text
Type: AFK
Status: open
Blocked by: T1

As the user, I select a task and press Command-Return to complete it.
Screens: 01-inbox.png, 02-today.png
Acceptance:
- [snap] The circle fills and the row fades out within half a second.
- [self] An "Undo" banner shows for five seconds; Command-Z also undoes it.
- [unit] A recurring task moves to its next date.
```

- `Type:` is `AFK` when an agent can finish and check it alone, `HITL`
  when it needs a person: a judgement call, or a check only a person can
  make (drag and drop feel, a real iCloud account).
- `Blocked by:` (optional) lists tickets that must be done first.
- Every acceptance line starts with how it is checked: `[snap]` snapshot,
  `[unit]` unit test, `[self]` self-test, `[manual]` a person must try it.
  "Works well" is not checkable.
- `[unit]` is only for logic in the `<App>Core` package, which the tests
  build without the app. Model and storage behavior (Core Data
  entities, delete rules, saving) lives in the app target, so check it with
  `[self]`.
- `Screens:` links reference screenshots in `docs/screens/`, so
  `bama-improve-loop` knows what to compare. Without a reference app, name
  the snapshot pages that will show the ticket. A panel, sheet, or menu
  needs its own snapshot page.
- Keep a control and the only surface that shows it in one ticket: a
  highlighting field that lives only in the quick-add panel ships with the
  panel.
- Every attribute the seed data sets (symbols, colors, notes) is something
  a ticket lets the user create. Otherwise snapshots show features no one
  can use.

The first milestone has 5 to 10 tickets. More than about 15 in any
milestone means it is too big: move stories to the spec's Out of Scope,
or to a later milestone's one-line scope.

Check: every user story in the spec maps to a ticket or to a line in Out
of Scope.

## 3. UX notes

For each ticket that adds a screen, an action, or words, call the Skill
tool with `bama-ux-design`. It adds a `UX:` block to the ticket's note and
puts new terms in `CONTEXT.md`.

Check: every such ticket has a `UX:` block.

## 4. Tag and order

Tag each ticket with the app's triage tags. `AFK` tickets get
`ready-for-agent`, `HITL` tickets get `ready-for-human`:

```bash
tools/omnifocus-setup.sh <App> tag <task-id> ready-for-agent
```

The OmniFocus MCP server matches tags by bare name, so it would add
another app's tag. The script looks the tag up in "<App> triage".

Write the order into the milestone action's note, under the Spec and
branch lines: "T1 first. T2 and T3 can run in parallel after T1. T4 needs
T2."

Check: every ticket has exactly one triage tag from "<App> triage".

Done when every user story in the spec maps to a ticket or an Out of
Scope line, every ticket has a type, a status, checkable acceptance lines,
and a triage tag, every UI ticket has a `UX:` block, and the action's note
gives the order.
