#!/bin/zsh
# Builds __APP_NAME__ and installs it to ~/Applications/__APP_NAME__.app.
# Generates __APP_NAME__.xcodeproj from project.yml when project.yml changed,
# then builds with xcodebuild. Build products live in
# ~/Library/Developer/__APP_NAME__, outside the repo (and outside Dropbox or
# iCloud, which would try to sync them).
#
# Usage: ./build.sh            release build, install
#        ./build.sh --debug    debug build (uses __APP_NAME__-dev.sqlite), install
#        ./build.sh --open     install, then quit the running copy and open the new one
set -euo pipefail
here=${0:A:h}
name="__APP_NAME__"
derived="$HOME/Library/Developer/$name/DerivedData"
config=Release
[[ " $* " == *" --debug "* ]] && config=Debug

# xcodebuild, momc and the Swift macros need a full Xcode, not the Command
# Line Tools. Use the selected Xcode, or /Applications/Xcode.app.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  selected=$(xcode-select -p 2>/dev/null || true)
  [[ "$selected" == */Xcode*.app/Contents/Developer ]] && DEVELOPER_DIR=$selected || DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
[[ -d "$DEVELOPER_DIR" ]] || { echo "no Xcode at $DEVELOPER_DIR: install Xcode or set DEVELOPER_DIR"; exit 1; }
export DEVELOPER_DIR

command -v xcodegen >/dev/null || { echo "xcodegen is missing: brew install xcodegen"; exit 1; }
project="$here/$name.xcodeproj"
if [[ ! -d "$project" || "$here/project.yml" -nt "$project/project.pbxproj" ]]; then
  xcodegen generate --spec "$here/project.yml" --quiet
fi

# Sign the installed copy with your Apple Development certificate when you
# have one (Xcode > Settings > Accounts). Otherwise sign ad hoc, which is fine
# for your own Mac.
identity="${SIGN_IDENTITY:-}"
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"' || true)
fi
[[ -n "$identity" ]] || identity=-

log="$HOME/Library/Developer/$name/build.log"
mkdir -p "${log:h}"
if ! xcodebuild -project "$project" -scheme "$name" -configuration $config \
     -derivedDataPath "$derived" -destination 'platform=macOS' build >"$log" 2>&1; then
  grep -E "error:|BUILD FAILED" "$log" | sort -u | head -20
  echo "build failed (full log: $log)"
  exit 1
fi
grep -E "warning:" "$log" | grep -v "^ld: warning\|appintentsmetadataprocessor" | sort -u | head -20 || true

built="$derived/Build/Products/$config/$name.app"
[[ -d "$built" ]] || { echo "build failed: no $built"; exit 1; }
app="$HOME/Applications/$name.app"
mkdir -p "$HOME/Applications"
rm -rf "$app"
cp -R "$built" "$app"
xattr -cr "$app"
codesign --force --deep --sign "$identity" "$app" 2>&1 | grep -v "replacing existing signature" || true
echo "installed $app ($config, signed: ${identity})"

if [[ " $* " == *" --open "* ]]; then
  osascript -e "quit app \"$name\"" 2>/dev/null || true
  sleep 0.5
  open "$app"
fi
