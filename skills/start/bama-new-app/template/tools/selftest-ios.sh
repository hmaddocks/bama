#!/bin/zsh
# Runs the iOS app's self-test in the iPhone 17 simulator against a fresh
# store in /tmp. Exit code 0 when every check passed. Builds and installs first.
set -euo pipefail
here=${0:A:h:h}
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
sim=${SIM_DEVICE:-iPhone 17}
SIM_DEVICE=$sim "$here/build.sh" --ios >/dev/null
store=/tmp/__APP_NAME__-self-ios.sqlite
rm -f $store $store-shm $store-wal
sim_id=$(xcrun simctl list devices booted | grep -F "    $sim (" | grep -m1 -oE '[0-9A-F-]{36}')
out=$(SIMCTL_CHILD_APP_STORE=$store \
      xcrun simctl launch --console-pty --terminate-running-process "$sim_id" __BUNDLE_ID__ --selftest 2>&1)
print -r -- "$out" | grep -E "^(PASS|FAIL|SELFTEST)|refused"
# simctl launch exits 0 whatever the app does, so read its output.
print -r -- "$out" | grep -q "^SELFTEST PASS"
