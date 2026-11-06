#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Proves run-screenshot-tests.sh finds the screenshot tests and hands them to run-ui-tests.sh as it should. A copy of the
# script runs in a tree of its own with a stub runner, so this needs no simulator and runs on Linux.
#
# The convention it documents: a screenshot test is a `func test...` in
# Tests/AnkyUITests/Screenshots/<Group>ScreenshotTests.swift, and the class is named like the file. A test anywhere
# else, or in a file whose name does not end in ScreenshotTests, is not listed, and so it never runs.
here=$(cd "$(dirname "$0")" && pwd)
failures=0
root=$(mktemp -d)
trap 'rm -rf "${root:?}"' EXIT

report() {
  if [ "$2" = 0 ]; then echo "ok: $1"; else echo "FAIL: $1"; failures=$((failures + 1)); fi
}

# Builds a repo tree whose runner stub writes its arguments and the variables it was given to files.
new_tree() {
  tree=$(mktemp -d "$root/case.XXXXXX")
  shots=$tree/Tests/AnkyUITests/Screenshots
  mkdir -p "$tree/scripts/ci" "$shots"
  cp "$here/run-screenshot-tests.sh" "$tree/scripts/ci/run-screenshot-tests.sh"
  cat > "$tree/scripts/ci/run-ui-tests.sh" <<STUB
#!/bin/sh
echo "\$*" > "$tree/args.txt"
{
  echo "runtime=\${ANKY_SIM_RUNTIME-unset}"
  echo "look=\${TEST_RUNNER_ANKY_PRESENTATION-unset}"
  echo "shell-look=\${ANKY_PRESENTATION-unset}"
  echo "record=\${TEST_RUNNER_ANKY_RECORD_BASELINES-unset}"
  echo "seconds=\${UI_TRY_SECONDS-unset}"
} > "$tree/env.txt"
exit "\${STUB_STATUS:-0}"
STUB
  chmod +x "$tree/scripts/ci/run-ui-tests.sh"
  cat > "$shots/MedicationsScreenshotTests.swift" <<'SWIFT'
final class MedicationsScreenshotTests: XCTestCase {
    func testMedicationsEmptyLightDefault() {}
    func testMedicationsEmptyDarkLargest() {}
    private func helper() {}
}
SWIFT
  cat > "$shots/TodayScreenshotTests.swift" <<'SWIFT'
@MainActor
final class TodayScreenshotTests: XCTestCase {
    @MainActor func testTodayFullLightDefault() {}
}
SWIFT
}

# usage: run_script <args...>. Sets code to the script's exit status. The shell's own settings are cleared first.
run_script() {
  (cd "$tree" && env -u ANKY_RECORD_BASELINES -u UI_TRY_SECONDS -u ANKY_PRESENTATION \
    -u TEST_RUNNER_ANKY_RECORD_BASELINES -u TEST_RUNNER_ANKY_PRESENTATION -u ANKY_SIM_RUNTIME \
    "$@") > "$tree/out.txt" 2>&1
  code=$?
}

script=scripts/ci/run-screenshot-tests.sh

new_tree
run_script sh "$script" --list
[ "$code" -eq 0 ] && [ "$(cat "$tree/out.txt")" = "$(printf '%s\n' \
  MedicationsScreenshotTests/testMedicationsEmptyLightDefault \
  MedicationsScreenshotTests/testMedicationsEmptyDarkLargest \
  TodayScreenshotTests/testTodayFullLightDefault)" ] && [ ! -e "$tree/args.txt" ]
report "--list prints every test of every screenshot file and starts no run" $?

name="--list does not show a test outside the Screenshots folder or in a file not named ...ScreenshotTests"
new_tree
cat > "$tree/Tests/AnkyUITests/ElsewhereScreenshotTests.swift" <<'SWIFT'
final class ElsewhereScreenshotTests: XCTestCase {
    func testElsewhere() {}
}
SWIFT
cat > "$shots/Misnamed.swift" <<'SWIFT'
final class MisnamedScreenshotTests: XCTestCase {
    func testMisnamed() {}
}
SWIFT
cat > "$shots/NotesScreenshotSteps.swift" <<'SWIFT'
func testNotATest() {}
SWIFT
run_script sh "$script" --list
! grep -q 'Elsewhere\|Misnamed\|NotATest' "$tree/out.txt" && [ "$(wc -l < "$tree/out.txt")" -eq 3 ]
report "$name" $?

new_tree
run_script sh "$script" .derived
every="MedicationsScreenshotTests/testMedicationsEmptyLightDefault"
every="$every MedicationsScreenshotTests/testMedicationsEmptyDarkLargest TodayScreenshotTests/testTodayFullLightDefault"
[ "$code" -eq 0 ] && [ "$(cat "$tree/args.txt")" = "light .derived $every" ]
report "with no names every discovered test runs, on the light look" $?

new_tree
run_script sh "$script" .derived TodayScreenshotTests/testTodayFullLightDefault
[ "$code" -eq 0 ] && [ "$(cat "$tree/args.txt")" = "light .derived TodayScreenshotTests/testTodayFullLightDefault" ]
report "named tests are the only ones that run" $?

new_tree
run_script sh "$script" .derived
grep -qx 'runtime=com.apple.CoreSimulator.SimRuntime.iOS-26-5' "$tree/env.txt" && grep -qx 'look=english' "$tree/env.txt" \
  && grep -qx 'seconds=2400' "$tree/env.txt" && grep -qx 'record=unset' "$tree/env.txt"
report "by default the runtime is iOS 26.5, the look english, a try 2400 s, and nothing is recorded" $?

new_tree
(cd "$tree" && ANKY_PRESENTATION=rightToLeft TEST_RUNNER_ANKY_PRESENTATION=doubleLength sh "$script" .derived) \
  > "$tree/out.txt" 2>&1
grep -qx 'look=english' "$tree/env.txt" && grep -qx 'shell-look=unset' "$tree/env.txt"
report "a look left in the shell does not reach the run" $?

new_tree
(cd "$tree" && ANKY_RECORD_BASELINES=1 sh "$script" .derived) > "$tree/out.txt" 2>&1
grep -qx 'record=1' "$tree/env.txt"
report "ANKY_RECORD_BASELINES reaches the test process" $?

new_tree
(cd "$tree" && TEST_RUNNER_ANKY_RECORD_BASELINES=1 sh "$script" .derived) > "$tree/out.txt" 2>&1
grep -qx 'record=unset' "$tree/env.txt"
report "recording left on in the test variable alone does not reach the test process" $?

new_tree
(cd "$tree" && UI_TRY_SECONDS=90 sh "$script" .derived) > "$tree/out.txt" 2>&1
grep -qx 'seconds=90' "$tree/env.txt"
report "UI_TRY_SECONDS set by the caller is kept" $?

new_tree
(cd "$tree" && STUB_STATUS=65 sh "$script" .derived) > "$tree/out.txt" 2>&1
code=$?
[ "$code" -eq 65 ]
report "the exit status is the runner's" $?

new_tree
bad=0
for args in "" "--list .derived" "--lst"; do
  # shellcheck disable=SC2086
  run_script sh "$script" $args
  { [ "$code" -eq 2 ] && grep -q '^usage:' "$tree/out.txt" && [ ! -e "$tree/args.txt" ]; } || bad=1
done
[ "$bad" = 0 ]
report "no arguments, --list with another argument, and an unknown option exit 2 with the usage" $?

name="no screenshot test found exits 2 and never runs the whole UI suite"
new_tree
rm "$shots"/*.swift
run_script sh "$script" .derived
[ "$code" -eq 2 ] && [ ! -e "$tree/args.txt" ]
report "$name" $?

[ "$failures" = 0 ] && echo "run-screenshot-tests tests: all passed"
exit "$failures"
