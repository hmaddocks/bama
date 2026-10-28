#!/bin/zsh
# Sets up OmniFocus for an app, and tags its tickets.
# Usage: omnifocus-setup.sh <App>                          project "<App> App" and tag group "<App> triage"
#        omnifocus-setup.sh <App> tag <task-id> <tag>      add "<App> triage" > <tag> to a task
#        omnifocus-setup.sh <App> status <task-id> <status> set the ticket's "Status:" line (open, claimed)
#        omnifocus-setup.sh <App> resolve <task-id> <answer> append "Answer", set "Status: resolved", complete it
# Safe to run again: it creates only what is missing.
# The OmniFocus MCP server finds a tag by its bare name and cannot nest tags,
# so it would add another app's ready-for-agent. This script looks the tag up
# inside the app's own group. The MCP server can only replace a whole note,
# so status changes go through here too.
set -euo pipefail
app=${1:?usage: omnifocus-setup.sh <App> [tag <task-id> <tag>]}
mode=${2:-setup}
osascript - "$app" "$mode" "${3:-}" "${4:-}" <<'EOF'
on run argv
  set appName to item 1 of argv
  set mode to item 2 of argv
  set groupName to appName & " triage"
  tell application "OmniFocus"
    tell default document
      if mode is "tag" then
        set taskID to item 3 of argv
        set tagName to item 4 of argv
        set grp to first tag whose name is groupName
        set theTag to first tag of grp whose name is tagName
        set t to first flattened task whose id is taskID
        add theTag to tags of t
        return "tagged " & name of t & " with " & groupName & " > " & tagName
      end if

      if mode is "status" or mode is "resolve" then
        set t to first flattened task whose id is (item 3 of argv)
        set n to note of t
        set newStatus to "resolved"
        if mode is "status" then set newStatus to item 4 of argv
        -- Notes written by the MCP server split lines with a character that
        -- `paragraphs` does not see, so replace the known values instead.
        repeat with oldStatus in {"Status: open", "Status: claimed", "Status: resolved"}
          set AppleScript's text item delimiters to (oldStatus as text)
          set parts to text items of n
          set AppleScript's text item delimiters to "Status: " & newStatus
          set n to parts as text
        end repeat
        set AppleScript's text item delimiters to ""
        if mode is "resolve" then
          set n to n & linefeed & linefeed & "Answer" & linefeed & (item 4 of argv)
          set note of t to n
          mark complete t
        else
          set note of t to n
        end if
        return name of t & ": Status: " & newStatus
      end if

      set projectName to appName & " App"
      if (count of (flattened projects whose name is projectName)) is 0 then
        if (count of (flattened folders whose name is "Software Projects")) > 0 then
          set f to first flattened folder whose name is "Software Projects"
          make new project at end of projects of f with properties {name:projectName}
        else
          make new project with properties {name:projectName}
        end if
      end if

      if (count of (tags whose name is groupName)) is 0 then
        make new tag with properties {name:groupName}
      end if
      set grp to first tag whose name is groupName
      repeat with n in {"needs-triage", "needs-info", "ready-for-agent", "ready-for-human", "wontfix"}
        if (count of (tags of grp whose name is (n as text))) is 0 then
          make new tag at end of tags of grp with properties {name:(n as text)}
        end if
      end repeat
      set p to first flattened project whose name is projectName
      return "project " & projectName & " (" & id of p & "), tags " & groupName
    end tell
  end tell
end run
EOF
