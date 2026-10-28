#!/bin/zsh
# Links every skill in this repo into ~/.claude/skills and ~/.agents/skills,
# so edits in the repo show up in Claude Code and Codex at once.
# Usage: scripts/link-skills.sh
# A path that is already there and is not a link into this repo is left
# alone and reported, and the script exits 1 at the end.
set -euo pipefail
repo=${0:A:h:h}
skipped=0
for target in ~/.claude/skills ~/.agents/skills; do
  mkdir -p "$target"
  for skill in "$repo"/skills/*/*/; do
    skill=${skill%/}
    name=${skill:t}
    dest="$target/$name"
    if [[ -L "$dest" ]]; then
      current=$(readlink "$dest")
      if [[ "$current" != "$repo"/* ]]; then
        echo "skipped $dest: a link to $current, not into this repo"
        skipped=1
        continue
      fi
    elif [[ -e "$dest" ]]; then
      echo "skipped $dest: a folder or file that is not a link"
      skipped=1
      continue
    fi
    ln -sfn "$skill" "$dest"
    echo "$dest"
  done
done
exit $skipped
