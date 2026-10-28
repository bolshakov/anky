#!/bin/sh
# Runs the named UI tests, or every UI test, on a new simulator. Exits 0 only when xcodebuild test exits 0, every named
# test ran, and no test skipped. A try that runs past its limit is run once more on a rebooted simulator.
if [ $# -lt 2 ] || { [ "$1" != light ] && [ "$1" != dark ]; }; then
  echo "usage: run-ui-tests.sh <light|dark> <derived data dir> [Class/testMethod ...]" >&2
  exit 2
fi

# xcodebuild forwards only TEST_RUNNER_ variables, so the look goes in under that name.
look=${ANKY_PRESENTATION:-${TEST_RUNNER_ANKY_PRESENTATION:-english}}
case "$look" in
  english|doubleLength|rightToLeft) ;;
  *) echo "the look must be english, doubleLength or rightToLeft, not $look" >&2; exit 2 ;;
esac
export TEST_RUNNER_ANKY_PRESENTATION=$look

appearance=$1
derived=$2
shift 2

limit=${UI_TRY_SECONDS:-540}
udid=
xcb=
watcher=
work=$(mktemp -d)
log=$work/try.log
mark=$work/timed-out

# A plain TERM would wait for xcodebuild to exit first, so the trap has to stop it.
trap 'exit 143' TERM INT HUP

# Without job control, as in a shell with no tty, the group signal fails, so the pid alone gets the signal.
stop_group() {
  kill -s "$2" -- -"$1" 2>/dev/null || kill -s "$2" "$1" 2>/dev/null
}

cleanup() {
  status=$?
  [ -n "$watcher" ] && kill -s TERM "$watcher" 2>/dev/null
  [ -n "$xcb" ] && stop_group "$xcb" TERM
  if [ -n "$udid" ]; then
    xcrun simctl shutdown "$udid" > /dev/null 2>&1
    xcrun simctl delete "$udid" > /dev/null 2>&1
    echo "simulator $udid deleted"
  fi
  rm -rf "$work"
  echo "ui tests exit $status"
}
trap cleanup EXIT

# Stops the try's process group once the limit runs out, and leaves the mark file behind.
watch() {
  trap 'kill "$nap" 2>/dev/null; exit 0' TERM
  sleep "$limit" & nap=$!
  wait "$nap"
  touch "$mark"
  stop_group "$1" TERM
  sleep 2 & nap=$!
  wait "$nap"
  stop_group "$1" KILL
}

# Runs one try of xcodebuild test under the limit, and prints the test lines it wrote.
run_try() {
  rm -f "$mark"
  # Each name becomes its own argument, so no shell reads it as words or code.
  for name do
    set -- "$@" "-only-testing:AnkyUITests/$name"
    shift
  done
  set -m
  xcodebuild test -project Anky.xcodeproj -scheme Anky -destination "id=$udid" -derivedDataPath "$derived" \
    -clonedSourcePackagesDirPath .spm -retry-tests-on-failure -test-iterations 2 "$@" > "$log" 2>&1 < /dev/null &
  xcb=$!
  set +m
  watch "$xcb" &
  watcher=$!
  wait "$xcb"
  try_status=$?
  xcb=
  kill -s TERM "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  watcher=
  grep -E "^Test Case |error:" "$log"
}

# Whether xcodebuild printed a line with this result for the test, given as "Class method".
printed() {
  grep -qF "Test Case '-[AnkyUITests.$1]' $2" "$log"
}

# Judges the last try by the lines xcodebuild printed. Returns 1 when a named test did not run or a test skipped.
judge() {
  result=0
  if grep -q "^Test Case .* skipped" "$log"; then
    echo "a test was skipped, so the run fails"
    result=1
  fi
  for name do
    if ! printed "${name%/*} ${name#*/}" passed && ! printed "${name%/*} ${name#*/}" failed; then
      echo "not run: $name"
      result=1
    fi
  done
  sed -n "s/^Test Case '-\[AnkyUITests\.\(.*\)\]' failed.*/\1/p" "$log" | sort -u | while read -r failed_test; do
    if printed "$failed_test" passed; then
      echo "::warning::flaky: ${failed_test% *}/${failed_test#* } failed once, then passed"
    fi
  done
  return "$result"
}

udid=$(xcrun simctl create "anky-ui-$$" com.apple.CoreSimulator.SimDeviceType.iPhone-17) || exit 1
echo "simulator $udid"
xcrun simctl boot "$udid" || exit 1
xcrun simctl ui "$udid" appearance "$appearance" || exit 1

try=1
run_try "$@"
while [ -e "$mark" ]; do
  echo "try $try timed out after $limit s"
  [ "$try" = 2 ] && exit 1
  xcrun simctl shutdown "$udid" || exit 1
  xcrun simctl boot "$udid" || exit 1
  echo "simulator $udid rebooted"
  try=2
  run_try "$@"
done
[ "$try_status" = 0 ] || exit "$try_status"
judge "$@" || exit 1
