#!/bin/sh
# Exits with the status of xcodebuild test, so a failed test turns the step red.
if [ $# -lt 2 ] || { [ "$1" != light ] && [ "$1" != dark ]; }; then
  echo "usage: run-ui-tests.sh <light|dark> <derived data dir> [Class/testMethod ...]" >&2
  exit 2
fi
appearance=$1
derived=$2
shift 2

udid=
xcb=
log=$(mktemp)

# A plain TERM would wait for xcodebuild to exit first, so the trap has to stop it.
trap 'exit 143' TERM INT HUP

cleanup() {
  status=$?
  [ -n "$xcb" ] && kill "$xcb" 2>/dev/null
  if [ -n "$udid" ]; then
    xcrun simctl shutdown "$udid" > /dev/null 2>&1
    xcrun simctl delete "$udid" > /dev/null 2>&1
    echo "simulator $udid deleted"
  fi
  rm -f "$log"
  echo "ui tests exit $status"
}
trap cleanup EXIT

udid=$(xcrun simctl create "anky-ui-$$" com.apple.CoreSimulator.SimDeviceType.iPhone-17) || exit 1
echo "simulator $udid"
xcrun simctl boot "$udid" || exit 1
xcrun simctl ui "$udid" appearance "$appearance" || exit 1

# Each name becomes its own argument, so no shell reads it as words or code.
for name do
  set -- "$@" "-only-testing:AnkyUITests/$name"
  shift
done

xcodebuild test -project Anky.xcodeproj -scheme Anky -destination "id=$udid" -derivedDataPath "$derived" \
  -clonedSourcePackagesDirPath .spm -retry-tests-on-failure -test-iterations 2 "$@" > "$log" 2>&1 &
xcb=$!
wait "$xcb"
status=$?
xcb=
grep -E "^Test Case |error:" "$log"
exit "$status"
