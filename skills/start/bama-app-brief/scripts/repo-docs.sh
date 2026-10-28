#!/bin/zsh
# Writes an app's agent docs before the app is scaffolded: AGENTS.md (and a
# CLAUDE.md link to it), CONTEXT.md, docs/agents/, and tools/omnifocus-setup.sh.
# Usage: repo-docs.sh <AppName> <app-folder>
# The docs come from the bama-new-app template. Existing files are kept, and
# new-app.sh keeps these when it scaffolds the app later.
set -euo pipefail
name=${1:?usage: repo-docs.sh <AppName> <app-folder>}
dest=${2:?usage: repo-docs.sh <AppName> <app-folder>}
here=${0:A:h}
template=$here/../../bama-new-app/template
[[ -d "$template" ]] || { echo "bama-new-app template not found at $template"; exit 1; }
tag="apps/${name:l}"

mkdir -p "$dest/docs/agents" "$dest/tools"
for f in AGENTS.md CONTEXT.md docs/agents/issue-tracker.md docs/agents/triage-labels.md docs/agents/domain.md; do
  [[ -e "$dest/$f" ]] && continue
  sed -e "s/__APP_NAME__/$name/g" -e "s|__BEAR_TAG__|$tag|g" "$template/$f" > "$dest/$f"
done
[[ -e "$dest/CLAUDE.md" ]] || ln -s AGENTS.md "$dest/CLAUDE.md"
[[ -e "$dest/tools/omnifocus-setup.sh" ]] || cp "$here/omnifocus-setup.sh" "$dest/tools/omnifocus-setup.sh"
chmod +x "$dest/tools/omnifocus-setup.sh"
echo "wrote the agent docs in $dest"
