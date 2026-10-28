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
#        ./build.sh --ios      iOS target: build, install and launch in the iPhone 17
#                              simulator (SIM_DEVICE=<name or UDID> picks another)
#        ./build.sh --ios --device   the same on the connected iPhone or iPad
#                              (DEVICE=<name or id> picks one when several are connected)
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

log="$HOME/Library/Developer/$name/build.log"
mkdir -p "${log:h}"
# Builds a scheme into $derived, or prints the first errors and exits.
build() {
  if ! xcodebuild -project "$project" -scheme "$1" -configuration $config \
       -derivedDataPath "$derived" "${@:2}" build >"$log" 2>&1; then
    grep -E "error:|BUILD FAILED" "$log" | sort -u | head -20
    echo "build failed (full log: $log)"
    exit 1
  fi
  grep -E "warning:" "$log" | grep -v "^ld: warning\|appintentsmetadataprocessor" | sort -u | head -20 || true
}

if [[ " $* " == *" --ios "* ]]; then
  grep -q "^  ${name}iOS:" "$here/project.yml" || { echo "no ${name}iOS target in project.yml: add it with the bama-new-app skill's add-ios.sh"; exit 1; }
  if [[ " $* " == *" --device "* ]]; then
    # A paired iPhone or iPad that is reachable now (cable or Wi-Fi). Checked
    # before the build, so a missing device fails fast.
    devices=$(mktemp)
    xcrun devicectl list devices --json-output "$devices" >/dev/null 2>&1 || true
    device=$(/usr/bin/python3 - "$devices" "${DEVICE:-}" <<'PY'
import json, sys
want = sys.argv[2]
found = [d for d in json.load(open(sys.argv[1]))["result"]["devices"]
         if d["hardwareProperties"].get("reality") == "physical"
         and d["hardwareProperties"].get("platform") == "iOS"
         and d["connectionProperties"].get("pairingState") == "paired"
         and d["connectionProperties"].get("transportType")
         and want in ("", d["identifier"], d["deviceProperties"].get("name"))]
for d in found: print(d["identifier"], d["deviceProperties"].get("name"), sep="\t")
PY
)
    rm -f "$devices"
    [[ -n "$device" ]] || { echo "no iPhone or iPad connected${DEVICE:+ named $DEVICE}: connect it with a cable, unlock it, and tap Trust. Enable Developer Mode in Settings > Privacy & Security."; exit 1; }
    (( $(wc -l <<< "$device") == 1 )) || { echo "several devices connected; pick one with DEVICE=<name>:"; cut -f2 <<< "$device"; exit 1; }
    device_id=${device%%$'\t'*}
    # Automatic signing with DEVELOPMENT_TEAM from project.yml. The first
    # build registers the device and makes the provisioning profile.
    build "${name}iOS" -destination 'generic/platform=iOS' -allowProvisioningUpdates
    built="$derived/Build/Products/$config-iphoneos/${name}iOS.app"
    bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$built/Info.plist")
    xcrun devicectl device install app --device "$device_id" "$built" >/dev/null
    xcrun devicectl device process launch --terminate-existing --device "$device_id" "$bundle_id" >/dev/null \
      || echo "installed, but it did not launch: unlock the device, and trust your developer profile in Settings > General > VPN & Device Management"
    echo "installed ${name}iOS on ${device#*$'\t'} ($config)"
  else
    sim=${SIM_DEVICE:-iPhone 17}
    if [[ "$sim" =~ ^[0-9A-F-]{36}$ ]]; then
      sim_id=$sim
    else
      sim_id=$(xcrun simctl list devices available | grep -F "    $sim (" | grep -m1 -oE '[0-9A-F-]{36}' || true)
    fi
    [[ -n "$sim_id" ]] || { echo "no simulator named $sim: see xcrun simctl list devices available"; exit 1; }
    xcrun simctl boot "$sim_id" 2>/dev/null || true
    xcrun simctl bootstatus "$sim_id" -b >/dev/null
    build "${name}iOS" -destination "platform=iOS Simulator,id=$sim_id"
    built="$derived/Build/Products/$config-iphonesimulator/${name}iOS.app"
    bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$built/Info.plist")
    xcrun simctl install "$sim_id" "$built"
    xcrun simctl launch --terminate-running-process "$sim_id" "$bundle_id" >/dev/null
    # Shows the simulator's window, when Simulator.app is installed.
    open -b com.apple.iphonesimulator 2>/dev/null || true
    echo "installed ${name}iOS in the $sim simulator ($config)"
  fi
  exit 0
fi
grep -q "^  ${name}:" "$here/project.yml" || { echo "no Mac target in project.yml: build the iOS app with ./build.sh --ios"; exit 1; }

# Sign the installed copy with your Apple Development certificate when you
# have one (Xcode > Settings > Accounts). Otherwise sign ad hoc, which is fine
# for your own Mac.
identity="${SIGN_IDENTITY:-}"
if [[ -z "$identity" ]]; then
  identity=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -o '"Apple Development: [^"]*"' | tr -d '"' || true)
fi
[[ -n "$identity" ]] || identity=-

build "$name" -destination 'platform=macOS'

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
