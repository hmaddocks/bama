#!/bin/zsh
# Checks Icon/AppIcon.icon (an Icon Composer file) by compiling it with actool,
# the way Xcode does when it builds the app. Writes nothing into the repo.
# Run it after editing the icon, before tools/icon_review.sh.
set -euo pipefail
here=${0:A:h}
repo=${here:h}
icon="$repo/Icon/AppIcon.icon"
# actool and ictool ship with Xcode, not the Command Line Tools.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  selected=$(xcode-select -p 2>/dev/null || true)
  [[ "$selected" == */Xcode*.app/Contents/Developer ]] && DEVELOPER_DIR=$selected || DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export DEVELOPER_DIR
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# actool fails on a missing layer image, so it doubles as the validator.
# The .icon must be named AppIcon.icon to match --app-icon, or actool
# writes nothing and still exits 0. Check the output to catch that.
xcrun actool "$icon" --compile "$work" --platform macosx \
  --minimum-deployment-target 26.0 --app-icon AppIcon \
  --output-partial-info-plist "$work/partial.plist" \
  --output-format human-readable-text --errors --warnings >"$work/log" 2>&1 || { cat "$work/log"; exit 1; }
[[ -f "$work/Assets.car" && -f "$work/AppIcon.icns" ]] || { cat "$work/log"; echo "actool wrote no icon"; exit 1; }
echo "PASS the icon compiles (Assets.car and AppIcon.icns)"
