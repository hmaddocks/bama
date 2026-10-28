#!/bin/zsh
# Adds the iPhone and iPad target to a Mac app made with new-app.sh.
# Usage: add-ios.sh <app-folder>
#   add-ios.sh ~/Developer/Tasks
# Copies <App>iOS/ and tools/snap-ios.sh and selftest-ios.sh from the
# template, and appends the <App>iOS target to
# project.yml. Both targets share <App>Core. Commit the result yourself.
set -euo pipefail
app_dir=${1:?usage: add-ios.sh <app-folder>}
template=${0:A:h:h}/template
[[ -f "$app_dir/project.yml" ]] || { echo "no $app_dir/project.yml: is this an app from new-app.sh?"; exit 1; }
name=$(awk '/^name:/ { print $2; exit }' "$app_dir/project.yml")
bundle=$(awk '/PRODUCT_BUNDLE_IDENTIFIER:/ { print $2; exit }' "$app_dir/project.yml")
[[ -n "$name" && -n "$bundle" ]] || { echo "could not read name and PRODUCT_BUNDLE_IDENTIFIER from project.yml"; exit 1; }
[[ ! -e "$app_dir/${name}iOS" ]] || { echo "$app_dir/${name}iOS already exists"; exit 1; }
# The target block is appended, so `targets:` must be the last top-level key.
[[ $(grep -E '^[a-zA-Z]' "$app_dir/project.yml" | tail -1) == "targets:" ]] || { echo "targets: is not the last section of project.yml: paste project-ios.yml under it by hand"; exit 1; }
! grep -q "^  ${name}iOS:" "$app_dir/project.yml" || { echo "project.yml already has a ${name}iOS target"; exit 1; }

# A device build signs with your team: the OU of your Apple Development
# certificate. Without one, simulator builds still work.
team=$(security find-certificate -a -c "Apple Development" -p 2>/dev/null \
  | awk '/BEGIN/{n++} n==1' | openssl x509 -noout -subject 2>/dev/null \
  | sed -n 's/.*OU *= *\([A-Z0-9]*\).*/\1/p' || true)
fill() { sed -e "s/__APP_NAME__/$name/g" -e "s/__BUNDLE_ID__/$bundle/g" -e "s/__TEAM_ID__/${team:-\"\"}/g" "$1"; }

mkdir -p "$app_dir/${name}iOS"
for f in "$template"/__APP_NAME__iOS/*.swift; do
  fill "$f" > "$app_dir/${name}iOS/${f:t}"
done
fill "$template/project-ios.yml" >> "$app_dir/project.yml"
# xcodegen writes the target's Info.plist from project.yml.
[[ -f "$app_dir/.gitignore" ]] && ! grep -qx "/${name}iOS/Info.plist" "$app_dir/.gitignore" \
  && echo "/${name}iOS/Info.plist" >> "$app_dir/.gitignore"
# AGENTS.md gets the iPhone and iPad section, before "## Git".
if [[ -f "$app_dir/AGENTS.md" ]] && ! grep -q "ios-begin" "$app_dir/AGENTS.md"; then
  section=$(mktemp)
  sed -n '/<!-- ios-begin -->/,/<!-- ios-end -->/p' "$template/AGENTS.md" | fill /dev/stdin > "$section"
  if grep -q "^## Git" "$app_dir/AGENTS.md"; then
    awk -v f="$section" '/^## Git/ { while ((getline l < f) > 0) print l; print "" } { print }' "$app_dir/AGENTS.md" > "$section.new"
    mv "$section.new" "$app_dir/AGENTS.md"
  else
    { echo; cat "$section"; } >> "$app_dir/AGENTS.md"
  fi
  rm -f "$section"
fi
# The icon is shared by every platform: "shared" squares are macOS, iOS and iPadOS.
icon_json="$app_dir/Icon/AppIcon.icon/icon.json"
[[ -f "$icon_json" ]] && sed -i '' 's/"squares" : \[ "macOS" \]/"squares" : "shared"/' "$icon_json"
mkdir -p "$app_dir/tools"
for f in snap-ios.sh selftest-ios.sh; do
  fill "$template/tools/$f" > "$app_dir/tools/$f"
  chmod +x "$app_dir/tools/$f"
done

echo "added ${name}iOS to $app_dir. Next:"
echo "  1. move the seed data from ${name}/SeedData.swift into ${name}iOS/SeedData.swift if it has any"
echo "  2. ./build.sh --ios, tools/selftest-ios.sh and tools/snap-ios.sh, then commit"
