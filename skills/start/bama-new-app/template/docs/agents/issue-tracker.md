# Issue tracker: OmniFocus and Bear

Work on __APP_NAME__ is tracked in OmniFocus, project "__APP_NAME__ App",
through the OmniFocus MCP server. Specs live in Bear, through the Bear MCP
server, tagged #__BEAR_TAG__.

## Conventions

- The brief is the Bear note "__APP_NAME__ brief".
- A milestone is an action in "__APP_NAME__ App". All milestones are
  created up front, each with a one-line scope.
- A milestone's spec is a Bear note titled "__APP_NAME__ spec: <milestone>".
  Questions and answers from grilling go in a second note titled
  "__APP_NAME__: <milestone>".
- Specs live in Bear only. Nothing in this repo copies them.
- The action's note holds pointers, not the spec: the Bear note titles, the
  integration branch, the ticket order (for example "T1 first. T2 and T3
  can run in parallel after T1."), and a "Decisions so far:" list.
- Tickets are sub-actions named "T1 <title>", "T2 <title>". A ticket's note
  starts with `Type:` (AFK or HITL) and `Status:` (open, claimed, resolved)
  lines and an optional `Blocked by: T1, T2` line, then the story and its
  acceptance lines.
- Triage state is a tag from the "__APP_NAME__ triage" group (see
  `triage-labels.md`).

## Working a ticket

1. **Frontier**: the first ticket under the milestone that is incomplete,
   unblocked, `Status: open`, and tagged ready-for-agent.
2. **Claim**: set `Status: claimed` before any work.
3. Do the work on the integration branch. One commit per ticket.
4. **Resolve**: append an "Answer" section (the commit and anything a
   reader would not guess), set `Status: resolved`, and complete the
   sub-action.
5. Add one line under the milestone's "Decisions so far:".

## Tags

The OmniFocus MCP server finds a tag by its bare name and cannot nest
tags. Other projects have their own ready-for-agent tag, so the server
would pick the wrong one. Tag tickets with
`tools/omnifocus-setup.sh __APP_NAME__ tag <task-id> <tag>`, which looks
the tag up inside the app's own group.
