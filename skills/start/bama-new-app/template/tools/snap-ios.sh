#!/bin/zsh
# Snapshots of the iOS app with seed data on a fresh store in /tmp: the iPhone
# 17 in portrait and the iPad Pro 11-inch in landscape, light and dark.
# Writes /tmp/__APP_NAME__-shots-ios/<page>-<iphone|ipad>-<light|dark>.png.
# Builds and installs first. APP_SNAPSHOT_PAGES=main limits the pages.
set -euo pipefail
here=${0:A:h:h}
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
dir=/tmp/__APP_NAME__-shots-ios
rm -rf "$dir"
failed=0
for sim orientation in "iPhone 17" portrait "iPad Pro 11-inch (M5)" landscape; do
  SIM_DEVICE=$sim "$here/build.sh" --ios >/dev/null
  store=/tmp/__APP_NAME__-snap-ios.sqlite
  rm -f $store $store-shm $store-wal
  sim_id=$(xcrun simctl list devices booted | grep -F "    $sim (" | grep -m1 -oE '[0-9A-F-]{36}')
  out=$(SIMCTL_CHILD_APP_STORE=$store SIMCTL_CHILD_APP_SEED=1 SIMCTL_CHILD_APP_SNAPSHOT=$dir \
        SIMCTL_CHILD_APP_SNAPSHOT_ORIENTATION=$orientation SIMCTL_CHILD_APP_SNAPSHOT_PAGES=${APP_SNAPSHOT_PAGES:-} \
        xcrun simctl launch --console-pty --terminate-running-process "$sim_id" __BUNDLE_ID__ 2>&1)
  print -r -- "$out" | grep -E "^SNAPSHOT|refused"
  # simctl launch exits 0 whatever the app does, so read its output.
  print -r -- "$out" | grep -q "^SNAPSHOT done" || failed=1
done
exit $failed
