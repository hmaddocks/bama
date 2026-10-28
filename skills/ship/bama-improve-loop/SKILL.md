---
name: bama-improve-loop
description: Autonomous loop that works through one milestone's OmniFocus tickets for an app, one ticket per commit, building, snapshotting, comparing against reference screenshots, fixing, and resolving each ticket. Use when the user says "keep going", "work through the tickets", "build the milestone", "make it match the reference", or wants an unattended loop.
argument-hint: "[milestone name]"
---

# Improve loop

One pass through the loop takes one ticket from `open` to `resolved`:

```text
pick ticket -> claim -> plan -> code -> build -> snapshot -> compare -> fix -> commit -> resolve
```

The loop works on one milestone: an action in the app's OmniFocus project,
"<App> App". Use the milestone the user named, or the first incomplete
milestone action that has tickets. Its note names the spec, the
integration branch, and the ticket order. The conventions are in the app's
`docs/agents/issue-tracker.md`.

This needs the OmniFocus MCP server. If it is missing, say so, and stop.

Before the first ticket, check out the milestone's integration branch
(create it from main if it does not exist) and make sure the tree is
committed.

## 1. Pick and claim

The frontier is the first ticket under the milestone that is:

- incomplete in OmniFocus
- `Status: open` in its note
- tagged ready-for-agent from "<App> triage"
- not blocked: every ticket on its `Blocked by:` line is complete

Claim it before any work:

```bash
tools/omnifocus-setup.sh <App> status <task-id> claimed
```

The OmniFocus MCP server can only replace a whole note, so status changes
go through this script. Read the
milestone's spec in Bear, "<App> spec: <milestone>", for context.

No frontier left? Go to step 7.

## 2. Plan

If the ticket adds a screen, an action, or words and has no `UX:` block
yet, call the Skill tool with `bama-ux-design` first.

Write two to five lines in your head or in the commit body: which files
change, which model fields are new, which menu command and shortcut it adds,
which snapshot page shows it. If the ticket needs a new SwiftData field,
give it a default value so existing databases keep loading.

## 3. Code

Follow the `bama-swift` and `bama-mac-design` skills, the ticket's `UX:`
block, and `DESIGN.md` if the app has one. System hooks follow
`bama-os-integrations`. Keep each view file under about 300 lines.
Put new pages in the `SidebarItem` enum so snapshot mode visits them.
Use the terms in `CONTEXT.md`.

## 4. Build and snapshot

Follow the `bama-build-and-verify` skill. If the ticket has logic, add a
test or a self-test step (`bama-test-app` skill). Use seed data
(`APP_SEED=1`) so pages show real content.

## 5. Compare

Open your snapshot and the ticket's reference screenshot from
`docs/screens/` side by side with the Read tool. Write down the
differences that matter, in this order:

1. Missing or wrong behavior from the acceptance lines.
2. Words and flow: names, surface, and states that differ from the `UX:`
   block or the glossary in `CONTEXT.md`.
3. Layout: wrong column, wrong order, missing element, and every FAIL from
   the grid checks.
4. Hierarchy: what is biggest, boldest, first.
5. Spacing and alignment.
6. Color and details.

The goal is the same structure and behavior, built from Apple's own controls.
It is not a pixel copy. When the reference uses a web-style custom control
and macOS has a native one (a toolbar, a sidebar, a context menu, a date
picker), use the native one.

No reference screenshot (no app was cloned)? Compare against the ticket's
acceptance lines and the `bama-mac-design` rules instead.

Snapshot only the pages a ticket touches (`APP_SNAPSHOT_PAGES`), and the
full set when the milestone is done.

Fix, rebuild, and compare again. Three rounds per ticket at most. If it
still does not match, set it back with `tools/omnifocus-setup.sh <App>
status <task-id> open`, add a "Blocked" line to its note that says what is
blocking, and move on.

## 6. Commit and resolve

```bash
git add -A
git commit -m "Complete tasks with Command-Return"
```

One ticket per commit, so any ticket can be reverted on its own. The first
milestone may land as one commit when its tickets share one skeleton
(model, pages, list, persistence); after that, one ticket per commit.

Then, in OmniFocus:

1. Resolve the ticket. The answer is the commit hash, and anything a
   reader would not guess from the ticket:

   ```bash
   tools/omnifocus-setup.sh <App> resolve <task-id> "Commit abc1234. ..."
   ```

   It appends an `Answer` section, sets `Status: resolved`, and completes
   the sub-action.
2. Add one line under the milestone's "Decisions so far:" when the ticket
   settled a choice.

A new term or a decision that rules out an obvious alternative also goes
into `CONTEXT.md`, in the same commit.

When a ticket fixes a bug, add an entry to `docs/FIXLOG.md`: symptom,
cause, fix, and a last line `Rule: <what to always or never do>`. The fix
log outlives squashed history, and the milestone check-in reads it.

Back to step 1.

## 7. Milestone check-in and report

When no ready-for-agent ticket is left and every other ticket is complete,
call the Skill tool with `bama-improve-architecture`. Unattended, do its top
recommendation only if it is `Strong`, and leave the rest in the review
file for the user. Then complete the milestone action.

Report to the user:

- Tickets resolved, with one line each and the snapshot paths that show
  them.
- Tickets blocked, and why.
- Tickets tagged ready-for-human that are still open.
- Anything the user should try by hand (shortcuts, drag and drop).
- The next milestone in line, and whether it has a spec yet.

Then `./build.sh --open` so the user can try the new build. Merging the
integration branch into main is the user's call.

## Running it unattended

The loop works with no one watching, because every step checks itself:
the build, the snapshots, the acceptance lines. To let it run longer,
start it with a clear limit ("finish Core loop, then stop"), make sure the
tree is committed before you start, and never let it touch the user's real
database. Each ticket is a separate commit, so the user can review the
history in the morning and revert anything they do not like.

Done when every ready-for-agent ticket in the milestone is resolved or
named in the report as blocked with a reason, each resolved ticket has its
own commit and an Answer, and the user has the report.
