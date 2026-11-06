#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Runs the screenshot tests on an iPhone 17 simulator with the iOS 26.5 runtime, through run-ui-tests.sh. With no test
# names it runs every test found in Tests/AnkyUITests/Screenshots/*ScreenshotTests.swift. ANKY_RECORD_BASELINES=1
# rewrites the baselines instead of comparing.
here=$(cd "$(dirname "$0")" && pwd)
shots=$here/../../Tests/AnkyUITests/Screenshots

usage() {
  echo "usage: run-screenshot-tests.sh <derived data dir> [Class/testMethod ...]" >&2
  echo "       run-screenshot-tests.sh --list" >&2
  exit 2
}

# Prints Class/testMethod for each test, taking the class from the file name.
list_tests() {
  for file in "$shots"/*ScreenshotTests.swift; do
    [ -e "$file" ] || continue
    class=$(basename "$file" .swift)
    sed -n "s|^[[:space:]@A-Za-z]*func \(test[A-Za-z0-9_]*\)(.*|$class/\1|p" "$file"
  done
}

case "$1" in
  "") usage ;;
  --list) [ $# -eq 1 ] || usage; list_tests; exit 0 ;;
  -*) usage ;;
esac

derived=$1
shift
if [ $# -eq 0 ]; then
  # Without a name, run-ui-tests.sh would run every UI test, so a run that found no screenshot test stops here.
  set -- $(list_tests)
  [ $# -gt 0 ] || { echo "no screenshot test found under $shots" >&2; exit 2; }
fi

# ANKY_PRESENTATION in the shell would win over TEST_RUNNER_ANKY_PRESENTATION in run-ui-tests.sh.
unset ANKY_PRESENTATION
export TEST_RUNNER_ANKY_PRESENTATION=english
export ANKY_SIM_RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-5
export UI_TRY_SECONDS=${UI_TRY_SECONDS:-2400}
if [ -n "$ANKY_RECORD_BASELINES" ]; then
  export TEST_RUNNER_ANKY_RECORD_BASELINES=$ANKY_RECORD_BASELINES
else
  unset TEST_RUNNER_ANKY_RECORD_BASELINES
fi

exec "$here/run-ui-tests.sh" light "$derived" "$@"
