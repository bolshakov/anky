#!/bin/sh
# Proves run-ui-tests.sh fails on each kind of breakage. Stubs stand in for xcrun and xcodebuild, so it runs on Linux.
here=$(cd "$(dirname "$0")" && pwd)
runner=$here/run-ui-tests.sh
udid=STUB-UDID-0001
failures=0
root=$(mktemp -d)
trap 'rm -rf "${root:?}"' EXIT

report() {
  if [ "$2" = 0 ]; then echo "ok: $1"; else echo "FAIL: $1"; failures=$((failures + 1)); fi
}

# Each stub appends its call to one log, so the order of calls is visible.
new_tree() {
  tree=$(mktemp -d "$root/case.XXXXXX")
  bin=$tree/bin
  calls=$tree/calls.log
  out=$tree/out.log
  mkdir -p "$bin"
  cat > "$bin/xcrun" <<EOF
#!/bin/sh
echo "xcrun \$*" >> "$calls"
case "\$*" in
  "simctl create "*) echo "$udid" ;;
esac
EOF
  cat > "$bin/xcodebuild" <<EOF
#!/bin/sh
echo "xcodebuild \$*" >> "$calls"
case "\$STUB_XCODEBUILD" in
  hang) exec sleep 600 ;;
esac
status=0
for arg do
  case "\$arg" in
    -only-testing:AnkyUITests/*)
      name=\${arg#-only-testing:AnkyUITests/}
      if [ "\$STUB_XCODEBUILD" = fail ]; then
        echo "Test Case '-[AnkyUITests.\${name%/*} \${name#*/}]' failed (0.1 seconds)."
        status=65
      else
        echo "Test Case '-[AnkyUITests.\${name%/*} \${name#*/}]' passed (0.1 seconds)."
      fi ;;
  esac
done
exit \$status
EOF
  chmod +x "$bin/xcrun" "$bin/xcodebuild"
}

# usage: run_runner <pass|fail|hang> <runner args...>. Sets code to the runner's exit status.
run_runner() {
  mode=$1
  shift
  STUB_XCODEBUILD=$mode PATH="$bin:$PATH" "$runner" "$@" > "$out" 2>&1
  code=$?
}

new_tree
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
grep -qx "xcrun simctl delete $udid" "$calls"
report "the simulator is deleted after a pass" $?

new_tree
run_runner fail light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
grep -qx "xcrun simctl delete $udid" "$calls"
report "the simulator is deleted after a failure" $?

new_tree
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
grep -q '^xcodebuild ' "$calls" && sed -n '/^xcodebuild /q;p' "$calls" \
  | grep -qx "xcrun simctl ui $udid appearance light"
report "the look is set before the tests run" $?

new_tree
STUB_XCODEBUILD=hang PATH="$bin:$PATH" "$runner" light "$tree/.derived" \
  EmptyStateTests/testFirstLaunchShowsEmptyState > "$out" 2>&1 &
pid=$!
waited=0
until grep -q '^xcodebuild ' "$calls" 2>/dev/null || [ "$waited" -ge 30 ]; do sleep 1; waited=$((waited + 1)); done
kill -TERM "$pid" 2>/dev/null
waited=0
until grep -q '^ui tests exit' "$out" || [ "$waited" -ge 30 ]; do sleep 1; waited=$((waited + 1)); done
kill -KILL "$pid" 2>/dev/null
wait "$pid"
code=$?
grep -qx "xcrun simctl delete $udid" "$calls" && [ "$code" -ne 0 ]
report "the simulator is deleted when the runner is stopped" $?

new_tree
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState \
  SaveEntryTests/testSaveEntryOnToday
line=" $(grep '^xcodebuild ' "$calls") "
holds=0
case "$line" in *" -test-iterations 2 "*) ;; *) holds=1 ;; esac
case "$line" in *" -retry-tests-on-failure "*) ;; *) holds=1 ;; esac
case "$line" in *" -destination id=$udid "*) ;; *) holds=1 ;; esac
case "$line" in *" -derivedDataPath $tree/.derived "*) ;; *) holds=1 ;; esac
for name in EmptyStateTests/testFirstLaunchShowsEmptyState SaveEntryTests/testSaveEntryOnToday; do
  case "$line" in *" -only-testing:AnkyUITests/$name "*) ;; *) holds=1 ;; esac
done
[ "$holds" = 0 ]
report "xcodebuild gets one simulator, the retry flag and each named test" $?

new_tree
run_runner fail light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
grep -qF "Test Case '-[AnkyUITests.EmptyStateTests testFirstLaunchShowsEmptyState]' failed" "$out" \
  && [ "$(tail -n 1 "$out")" = "ui tests exit 65" ]
report "a failed test is named and sets the exit status" $?

new_tree
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
[ "$code" -eq 0 ] && grep -qx "simulator $udid" "$out" && grep -qx "simulator $udid deleted" "$out" \
  && [ "$(tail -n 1 "$out")" = "ui tests exit 0" ]
report "a passing run names its simulator and exits zero" $?

[ "$failures" = 0 ] && echo "run-ui-tests tests: all passed"
exit "$failures"
