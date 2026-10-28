---
name: bama-feature-spec
description: Milestone spec for an app, written to Bear after grilling the user one question at a time. Use when a milestone in the app's OmniFocus project has no spec yet, before bama-user-stories, or when the user asks to spec, plan, or grill a milestone or feature.
argument-hint: "[milestone name]"
---

# Feature spec

One run specs one milestone. The spec is a Bear note, "<App> spec:
<milestone>". The questions and answers that shaped it are a second note,
"<App>: <milestone>". Specs live in Bear only. Nothing goes into the repo
except new terms and decisions in `CONTEXT.md`.

This needs the OmniFocus and Bear MCP servers. If either is missing, say
which, and stop.

## 1. Pick the milestone and read

Find the app's OmniFocus project, "<App> App". Take the milestone the user
named, or the first incomplete milestone action whose note has no "Spec:"
line.

Read:

- the Bear note "<App> brief"
- `CONTEXT.md` in the app's repo: the glossary and the decisions
- the specs of earlier milestones, "<App> spec: <earlier milestone>"
- "<App>: screens" and the "<App> research: <topic>" notes, where they
  exist
- the code, when earlier milestones are built: what exists decides what
  this one changes

Check: you can say in one sentence what this milestone adds, and which
questions the brief and earlier specs leave open.

## 2. Grill

Ask one question at a time. Each question names your recommended answer
and why, so the user can reply "yes". Work down the decision tree: settle
a question before the ones that depend on it. When the code or a note can
answer a question, look it up instead of asking.

Cover, for this milestone:

- what the user does, step by step, and what they see
- the data: new types and fields, and what happens to existing data
- edge cases: empty, many, long text, deleted while open, undo
- where each feature opens (inline, popover, sheet, window), and its
  menu command and shortcut
- departures from platform defaults: name the default and what the
  departure costs, and get a yes before speccing it
- what is out of this milestone

Append each question and answer to "<App>: <milestone>" as you go, under a
`## Q<n>. <question>` heading. Create the note on the first answer, tagged
#apps/<app>.

New terms go into the `## Glossary` of `CONTEXT.md`. A choice that rules out
an obvious alternative goes into `## Decisions`, with the options
considered and the consequences.

Check: no open question would change what gets built, and every answer is
in the Q&A note.

## 3. Write the spec

Write "<App> spec: <milestone>", tagged #apps/<app>, with these sections in
this order:

```markdown
## Problem Statement
What the user cannot do yet, and why it matters.

## Solution
What the milestone adds, from the user's side.

## User Stories
1. As <the user>, I want <action>, so that <reason>.

## Implementation Decisions
Modules, types, data changes, platform choices. Names from the glossary.

## Testing Decisions
What a good test checks here, which seams, prior art in the code.

## Out of Scope
What this milestone leaves out, one line each.

## Further Notes
Departures from platform defaults the user agreed to, and anything else.
```

One user story per action a person takes, with every edge case from step 2
as its own story. Write plainly: short sentences, the glossary's terms.

Check: every answer in the Q&A note shows up in the spec or in Out of
Scope.

## 4. Point the milestone at it

Set the milestone action's note to:

```text
Spec: Bear note "<App> spec: <milestone>" (#apps/<app>). Questions and answers: Bear note "<App>: <milestone>".
Integration branch: <milestone-in-kebab-case>

Decisions so far:
```

Keep any one-line scope already in the note above the Spec line.

Then call the Skill tool with `bama-user-stories` to break the spec into
tickets.

Done when the spec note has all seven sections, the Q&A note holds every
question asked, `CONTEXT.md` has every new term and decision, and the
milestone action's note points at both notes.
