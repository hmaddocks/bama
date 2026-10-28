#!/bin/zsh
# Renders Icon/AppIcon.icon the way macOS shows it, with Icon Composer's
# ictool, into one contact sheet:
#   Default, Dark, TintedDark, ClearLight at 256 pt, then Default at 32 and 16 pt.
# With --ios, the way iPhone and iPad show it: the small sizes are 60 pt
# (Home Screen) and 29 pt (Settings).
# Usage: tools/icon_review.sh [--ios] [out.png]
#        (default /tmp/__APP_NAME__-icon.png, or /tmp/__APP_NAME__-icon-ios.png)
set -euo pipefail
here=${0:A:h}
repo=${here:h}
platform=macOS small=(32 16) out=/tmp/__APP_NAME__-icon.png
if [[ "${1:-}" == --ios ]]; then
  platform=iOS small=(60 29) out=/tmp/__APP_NAME__-icon-ios.png
  shift
fi
out=${1:-$out}
# actool and ictool ship with Xcode, not the Command Line Tools.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  selected=$(xcode-select -p 2>/dev/null || true)
  [[ "$selected" == */Xcode*.app/Contents/Developer ]] && DEVELOPER_DIR=$selected || DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export DEVELOPER_DIR
ictool="$DEVELOPER_DIR/../Applications/Icon Composer.app/Contents/Executables/ictool"
[[ -x "$ictool" ]] || { echo "ictool not found. Install Xcode 26 or later."; exit 1; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

render() { # rendition size file
  "$ictool" "$repo/Icon/AppIcon.icon" --export-image --output-file "$work/$3" \
    --platform $platform --rendition "$1" --width "$2" --height "$2" --scale 2 >/dev/null
}
render Default 256 1.png
render Dark 256 2.png
render TintedDark 256 3.png
render ClearLight 256 4.png
render Default ${small[1]} 5.png
render Default ${small[2]} 6.png
swift "$here/icon_sheet.swift" "$out" "$work"/{1,2,3,4,5,6}.png
echo "wrote $out"
