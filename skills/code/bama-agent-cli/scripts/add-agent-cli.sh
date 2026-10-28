#!/bin/zsh
# Adds the agent CLI and MCP server to an app made from the bama-new-app skeleton.
# Usage: add-agent-cli.sh <app-folder> <cli-name>
#   add-agent-cli.sh ~/Developer/Tasks tasks
# Copies <App>/Agent/*.swift, makes main.swift run the CLI before the app
# starts, starts the socket in AppDelegate, and makes build.sh link
# ~/.local/bin/<cli-name>. Agent/AgentCommands.swift has a status command and
# commented examples; add the app's own (bama-agent-cli skill, step 3).
set -euo pipefail
app_dir=${1:?usage: add-agent-cli.sh <app-folder> <cli-name>}
cli=${2:?usage: add-agent-cli.sh <app-folder> <cli-name>}
[[ "$cli" =~ ^[a-z][a-z0-9-]*$ ]] || { echo "cli-name must be lowercase letters, digits, and dashes, like tasks or mail"; exit 1; }
here=${0:A:h}
template=${here:h}/template
[[ -f "$app_dir/project.yml" ]] || { echo "no $app_dir/project.yml: is this an app from the bama-new-app skeleton?"; exit 1; }
name=$(awk '/^name:/ { print $2; exit }' "$app_dir/project.yml")
src="$app_dir/$name"
[[ -f "$src/main.swift" && -f "$src/AppDelegate.swift" ]] || { echo "no $src/main.swift or AppDelegate.swift"; exit 1; }
[[ ! -e "$src/Agent" ]] || { echo "$src/Agent already exists"; exit 1; }

mkdir -p "$src/Agent"
for f in "$template"/Agent/*.swift; do
  sed -e "s/__APP_NAME__/$name/g" -e "s/__CLI_NAME__/$cli/g" "$f" > "$src/Agent/${f:t}"
done

# main.swift: a command after the app's name runs the CLI and exits;
# anything else starts the app as before.
if ! grep -q "AgentCLI.runIfRequested" "$src/main.swift"; then
  perl -0pi -e 's/(_ = NSApplicationMain)/\/\/ `<app> <command>` runs the agent CLI and exits; anything else starts the app.\nif let code = MainActor.assumeIsolated({ AgentCLI.runIfRequested() }) { exit(code) }\n\n$1/' "$src/main.swift"
fi

# AppDelegate: start the socket once the store is open, before the self-test
# and snapshot mode run.
if ! grep -q "AgentSocket.listen" "$src/AppDelegate.swift"; then
  perl -0pi -e 's/^(\s*)SeedData\.insertIfRequested\(into: store\)\n/$1AgentRouter.store = store\n$1AgentSocket.listen { AgentRouter.handle(\$0) }\n$1SeedData.insertIfRequested(into: store)\n/m' "$src/AppDelegate.swift"
  grep -q "AgentSocket.listen" "$src/AppDelegate.swift" && started=1
fi

# build.sh puts the CLI on PATH.
if ! grep -q "local/bin/$cli" "$app_dir/build.sh"; then
  perl -0pi -e "s|(echo \"installed \\\$app[^\n]*\n)|\$1# The CLI: the app binary under a short name on PATH (bama-agent-cli skill).\nmkdir -p \"\\\$HOME/.local/bin\"\nln -sf \"\\\$app/Contents/MacOS/\\\$name\" \"\\\$HOME/.local/bin/$cli\"\n|" "$app_dir/build.sh"
  grep -q "local/bin/$cli" "$app_dir/build.sh" || echo "note: add the ~/.local/bin/$cli link to build.sh by hand"
fi

# New files join the build when the project is regenerated.
touch "$app_dir/project.yml"

echo "added the agent CLI to $name as \`$cli\`. Next (bama-agent-cli skill):"
echo "  3. add the app's commands in $src/Agent/AgentCommands.swift"
[[ -n "${started:-}" ]] || echo "  4. start the socket in AppDelegate after the store opens: AgentRouter.store = store; AgentSocket.listen { AgentRouter.handle(\$0) }"
echo "  5. ./build.sh, then $cli help"
