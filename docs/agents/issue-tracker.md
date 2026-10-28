# Issue tracker: OmniFocus and Bear

Work on BAMA is tracked in OmniFocus, project "BAMA App" in the Software
Projects folder, through the OmniFocus MCP server. Specs live in Bear,
through the Bear MCP server, tagged #apps/bama.

## Conventions

- A stage or feature is an action in "BAMA App", for example "Stage 2:
  Planning and docs".
- Its spec is a Bear note titled "BAMA spec: <feature>". Questions and
  answers from grilling go in a second note titled "BAMA: <feature>".
- Specs live in Bear only. Nothing in this repo copies them.
- The action's note holds pointers, not the spec: the Bear note titles, the
  integration branch, the ticket order (for example "T1 first. T2 and T3
  can run in parallel after T1."), and a "Decisions so far:" list.
- Tickets are sub-actions named "T1 <title>", "T2 <title>". A ticket's note
  starts with `Type:` (AFK or HITL) and `Status:` (open, claimed, resolved)
  lines and an optional `Blocked by: T1, T2` line, then the body and its
  acceptance checks.
- Triage state is a tag from the "BAMA triage" group (see
  `triage-labels.md`).

## Working a ticket

1. **Frontier**: the first ticket under the action that is incomplete,
   unblocked, `Status: open`, and tagged ready-for-agent.
2. **Claim**: set `Status: claimed` before any work.
3. Do the work on the integration branch. One commit per ticket.
4. **Resolve**: append an "Answer" section (the commit and anything a
   reader would not guess), set `Status: resolved`, and complete the
   sub-action.
5. Add one line under the action's "Decisions so far:".
6. When every ticket is done, complete the action.

## Tags

The OmniFocus MCP server finds a tag by its bare name and cannot nest
tags. Other projects have their own ready-for-agent tag, so the server
would pick the wrong one. Add and create "BAMA triage" tags with
AppleScript (`osascript`), looking the tag up inside the "BAMA triage"
group.
