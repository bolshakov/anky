#!/bin/sh
# Proves run-ui-tests.sh fails on each kind of breakage. Stubs stand in for xcrun and xcodebuild, so it runs on Linux.
here=$(cd "$(dirname "$0")" && pwd)
runner=$here/run-ui-tests.sh
udid=STUB-UDID-0001
failures=0
root=$(mktemp -d)
trap 'cat "$root"/case.*/children.pid 2>/dev/null | xargs kill 2>/dev/null; rm -rf "${root:?}"' EXIT

report() {
  if [ "$2" = 0 ]; then echo "ok: $1"; else echo "FAIL: $1"; failures=$((failures + 1)); fi
}

# Each stub appends its call to one log, so the order of calls is visible.
new_tree() {
  tree=$(mktemp -d "$root/case.XXXXXX")
  bin=$tree/bin
  calls=$tree/calls.log
  out=$tree/out.log
  omit=
  seconds=
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
  hang) sleep 60 & echo \$! >> "$tree/children.pid"; wait ;;
  hang-once)
    [ "\$(grep -c '^xcodebuild ' "$calls")" -gt 1 ] || { sleep 60 & echo \$! >> "$tree/children.pid"; wait; } ;;
  skip-unnamed)
    echo "Test Case '-[AnkyUITests.EmptyStateTests testFirstLaunchShowsEmptyState]' passed (0.1 seconds)."
    echo "Test Case '-[AnkyUITests.SaveEntryTests testSaveEntryOnToday]' skipped (0.0 seconds)." ;;
esac
status=0
for arg do
  case "\$arg" in
    -only-testing:AnkyUITests/*)
      name=\${arg#-only-testing:AnkyUITests/}
      case_line="Test Case '-[AnkyUITests.\${name%/*} \${name#*/}]'"
      case "\$STUB_XCODEBUILD" in
        fail) echo "\$case_line failed (0.1 seconds)."; status=65 ;;
        skip) echo "\$case_line skipped (0.0 seconds)." ;;
        flaky)
          echo "\$case_line failed (0.1 seconds)."
          echo "\$case_line passed (0.1 seconds)." ;;
        *) [ "\$name" = "\$STUB_OMIT" ] || echo "\$case_line passed (0.1 seconds)." ;;
      esac ;;
  esac
done
exit \$status
EOF
  chmod +x "$bin/xcrun" "$bin/xcodebuild"
}

# usage: run_runner <stub mode> <runner args...>. Sets code to the runner's exit status and elapsed to its run time.
# Runs the runner under bash. The hang cases need xcodebuild in its own process group, which dash may not give.
run_runner() {
  mode=$1
  shift
  start=$(date +%s)
  STUB_XCODEBUILD=$mode STUB_OMIT=$omit UI_TRY_SECONDS=$seconds PATH="$bin:$PATH" bash "$runner" "$@" > "$out" 2>&1
  code=$?
  elapsed=$(($(date +%s) - start))
}

# Polls for up to 5 seconds, and fails unless every child the hang stub started is gone.
children_gone() {
  for _ in 1 2 3 4 5; do
    alive=
    for pid in $(cat "$tree/children.pid" 2>/dev/null); do
      kill -0 "$pid" 2>/dev/null && alive=1
    done
    [ -z "$alive" ] && return 0
    sleep 1
  done
  return 1
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
STUB_XCODEBUILD=hang PATH="$bin:$PATH" bash "$runner" light "$tree/.derived" \
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
report "each named test reaches xcodebuild with two iterations" $?

new_tree
run_runner fail light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
grep -qF "Test Case '-[AnkyUITests.EmptyStateTests testFirstLaunchShowsEmptyState]' failed" "$out" \
  && [ "$(tail -n 1 "$out")" = "ui tests exit 65" ] && [ "$code" -eq 65 ]
report "a failed test exits non-zero" $?

new_tree
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
[ "$code" -eq 0 ] && grep -qx "simulator $udid" "$out" && grep -qx "simulator $udid deleted" "$out" \
  && [ "$(tail -n 1 "$out")" = "ui tests exit 0" ]
report "a passing run names its simulator and exits zero" $?

name="a hung try is stopped, the simulator rebooted, and the second try passes"
new_tree
seconds=2
run_runner hang-once light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
between=$(sed -n '/^xcodebuild /,/^xcodebuild /p' "$calls" | sed '1d;$d')
[ "$code" -eq 0 ] && [ "$elapsed" -lt 30 ] && grep -qx "try 1 timed out after 2 s" "$out" \
  && grep -qx "simulator $udid rebooted" "$out" \
  && [ "$between" = "$(printf 'xcrun simctl shutdown %s\nxcrun simctl boot %s' "$udid" "$udid")" ] \
  && [ -s "$tree/children.pid" ] && children_gone \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

name="two hung tries exit non-zero and delete the simulator"
new_tree
seconds=2
run_runner hang light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
[ "$code" -ne 0 ] && [ "$elapsed" -lt 30 ] && grep -qx "try 2 timed out after 2 s" "$out" \
  && [ "$(grep -c '^xcodebuild ' "$calls")" -eq 2 ] \
  && [ -s "$tree/children.pid" ] && children_gone \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

name="a named test that did not run exits non-zero"
new_tree
omit=SaveEntryTests/testSaveEntryOnToday
run_runner pass light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState \
  SaveEntryTests/testSaveEntryOnToday
[ "$code" -ne 0 ] && grep -qx "not run: SaveEntryTests/testSaveEntryOnToday" "$out" \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

name="a skipped test exits non-zero"
new_tree
run_runner skip light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
[ "$code" -ne 0 ] && grep -qx "a test was skipped, so the run fails" "$out" \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

name="a skipped test fails the run when no test is named"
new_tree
run_runner skip-unnamed light "$tree/.derived"
[ "$code" -ne 0 ] && grep -qx "a test was skipped, so the run fails" "$out" && ! grep -q '^not run:' "$out" \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

name="a test that fails then passes stays green and warns"
new_tree
run_runner flaky light "$tree/.derived" EmptyStateTests/testFirstLaunchShowsEmptyState
[ "$code" -eq 0 ] \
  && grep -qx "::warning::flaky: EmptyStateTests/testFirstLaunchShowsEmptyState failed once, then passed" "$out" \
  && grep -qx "xcrun simctl delete $udid" "$calls"
report "$name" $?

[ "$failures" = 0 ] && echo "run-ui-tests tests: all passed"
exit "$failures"
