#!/bin/zsh
# Creates a new AppKit and/or UIKit app from the template next to this script.
# Usage: new-app.sh <AppName> <bundle-id> [parent-folder] [--platforms mac|ios|both]
#   new-app.sh Tasks com.yourname.tasks ~/Developer --platforms both
# --platforms defaults to mac. add-ios.sh adds the iOS target to a Mac app later.
# Creates <parent-folder>/<AppName>. If that folder exists, it must not have a
# project.yml yet; existing files (like the agent docs from bama-app-brief) are kept.
# AppName must be one word in UpperCamelCase (letters and digits only).
set -euo pipefail
usage="usage: new-app.sh <AppName> <bundle-id> [parent-folder] [--platforms mac|ios|both]"
platforms=mac
args=()
while (( $# )); do
  case $1 in
    --platforms) platforms=${2:?$usage}; shift 2 ;;
    --platforms=*) platforms=${1#*=}; shift ;;
    *) args+=("$1"); shift ;;
  esac
done
[[ "$platforms" == (mac|ios|both) ]] || { echo "--platforms must be mac, ios, or both"; exit 1; }
name=${args[1]:?$usage}
bundle=${args[2]:?$usage}
parent=${args[3]:-$PWD}
[[ "$name" =~ ^[A-Z][A-Za-z0-9]*$ ]] || { echo "AppName must be UpperCamelCase letters and digits, like Tasks or DailyLog"; exit 1; }
template=${0:A:h:h}/template
dest="$parent/$name"
# An existing folder is fine if it has no project yet (for example only the agent docs).
[[ ! -e "$dest/project.yml" ]] || { echo "$dest already has a project.yml"; exit 1; }

# build.sh needs xcodegen and a full Xcode (xcodebuild, momc, Swift macros).
command -v xcodegen >/dev/null || { echo "xcodegen is missing. Install it with: brew install xcodegen"; exit 1; }
xcode=$(xcode-select -p 2>/dev/null || true)
[[ "$xcode" == */Xcode*.app/Contents/Developer || -d /Applications/Xcode.app ]] || { echo "Xcode is missing. Install it from the App Store; the Command Line Tools are not enough."; exit 1; }

mkdir -p "$dest"
# rsync, not cp -n: macOS cp -n exits 1 whenever it skips a file that exists.
rsync -a --ignore-existing "$template/" "$dest/"
# Pick the targets. project-ios.yml is the iOS target block, appended under
# `targets:`; the Mac target sits between the mac-target markers.
if [[ "$platforms" == mac ]]; then
  rm -rf "$dest/__APP_NAME__iOS" "$dest"/tools/{snap,selftest}-ios.sh
else
  cat "$dest/project-ios.yml" >> "$dest/project.yml"
fi
rm "$dest/project-ios.yml"
if [[ "$platforms" == ios ]]; then
  sed -i '' '/# mac-target-begin/,/# mac-target-end/d' "$dest/project.yml"
  rm -rf "$dest/__APP_NAME__" "$dest"/tools/{snap,selftest}.sh
fi
# A device build signs with your team. It is the OU of your Apple Development
# certificate; without one, simulator builds still work.
team=$(security find-certificate -a -c "Apple Development" -p 2>/dev/null \
  | awk '/BEGIN/{n++} n==1' | openssl x509 -noout -subject 2>/dev/null \
  | sed -n 's/.*OU *= *\([A-Z0-9]*\).*/\1/p' || true)
# Rename every file and folder with __APP_NAME__ in its name, deepest first.
find "$dest" -depth -name '*__APP_NAME__*' | while read -r found; do
  mv "$found" "${found:h}/${${found:t}//__APP_NAME__/$name}"
done
# Replace the placeholders in every text file.
tag="apps/${name:l}"
grep -rlI "__APP_NAME__\|__BUNDLE_ID__\|__BEAR_TAG__\|__TEAM_ID__" "$dest" | while read -r f; do
  sed -i '' -e "s/__APP_NAME__/$name/g" -e "s/__BUNDLE_ID__/$bundle/g" -e "s|__BEAR_TAG__|$tag|g" -e "s/__TEAM_ID__/${team:-\"\"}/g" "$f"
done
# Claude Code reads CLAUDE.md; other agents read AGENTS.md. One file, two names.
[[ -e "$dest/CLAUDE.md" ]] || ln -s AGENTS.md "$dest/CLAUDE.md"
# The triage-tag script lives with bama-app-brief; the app keeps a copy for its tickets.
of_setup=${0:A:h:h:h}/bama-app-brief/scripts/omnifocus-setup.sh
[[ -e "$dest/tools/omnifocus-setup.sh" || ! -f "$of_setup" ]] || cp "$of_setup" "$dest/tools/omnifocus-setup.sh"
[[ -f "$dest/tools/omnifocus-setup.sh" ]] && chmod +x "$dest/tools/omnifocus-setup.sh"
chmod +x "$dest/build.sh" "$dest/bin/test" "$dest"/tools/*.sh

cd "$dest"
[[ -d .git ]] || git init -q
git add -A
git commit -qm "Create $name from the app template ($platforms)"
echo "created $dest"
echo "next: cd \"$dest\" && ./build.sh --open"
