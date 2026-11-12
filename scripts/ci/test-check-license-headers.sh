#!/bin/sh
# Proves check-license-headers.sh fails on each way a Swift file can miss the license line and passes on a clean tree.
here=$(cd "$(dirname "$0")" && pwd)
failures=0
header='// SPDX-License-Identifier: GPL-3.0-or-later'

failed() { echo "FAIL: $1 ($2)" && failures=$((failures + 1)); }

missing_lines() {
  printf '%s\n' "$1" | while IFS= read -r wanted; do
    printf '%s\n' "$2" | grep -Fxq -- "$wanted" || printf '%s\n' "$wanted"
  done
}

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree> <violation lines, one per line, for fail> [root, default .]
expect() {
  want=$1 desc=$2 setup=$3 lines=$4 root=${5:-.}
  tree=$(mktemp -d)
  mkdir -p "$tree/App" "$tree/Sources/AnkyDomain" "$tree/Tests/AnkyDomainTests"
  printf '%s\nimport Foundation\n' "$header" > "$tree/App/AnkyApp.swift"
  printf '%s\nimport Foundation\n' "$header" > "$tree/Sources/AnkyDomain/Clean.swift"
  printf '%s\nimport Testing\n' "$header" > "$tree/Tests/AnkyDomainTests/Clean.swift"
  printf '%s\n// swift-tools-version: 6.0\n' "$header" > "$tree/Package.swift"
  (cd "$tree" && eval "$setup")
  out=$(cd "$tree" && "$here/check-license-headers.sh" "$root" 2>&1)
  status=$?
  if [ "$want" = pass ]; then
    if [ "$status" != 0 ] || [ -n "$out" ]; then failed "$desc" "wanted a silent pass, got status $status: $out"; fi
  else
    missing=$(missing_lines "$lines" "$out")
    if [ "$status" != 1 ] || [ -n "$missing" ]; then
      failed "$desc" "wanted status 1 and every listed line, got status $status, missing '$missing': $out"
    fi
  fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" ":" ""
expect pass "a Swift file outside App, Sources and Tests" "mkdir -p Tools && printf 'import Foundation\n' > Tools/Gen.swift" ""
expect pass "a non-Swift file without a header" "printf 'notes\n' > App/notes.txt" ""
expect pass "a header with no newline after it" "printf '%s' '$header' > App/Bare.swift" ""

expect fail "an import and no header" "printf 'import Foundation\n' > App/Card.swift" \
  "LICENSE HEADER VIOLATION: ./App/Card.swift"
expect fail "a header on line 2" "printf 'import Foundation\n%s\n' '$header' > Sources/AnkyDomain/Second.swift" \
  "LICENSE HEADER VIOLATION: ./Sources/AnkyDomain/Second.swift"
expect fail "a blank first line above the header" "printf '\n%s\n' '$header' > App/Blank.swift" \
  "LICENSE HEADER VIOLATION: ./App/Blank.swift"
expect fail "an empty file" ": > App/Empty.swift" \
  "LICENSE HEADER VIOLATION: ./App/Empty.swift"
expect fail "a trailing space" "printf '%s \n' '$header' > App/Space.swift" \
  "LICENSE HEADER VIOLATION: ./App/Space.swift"
expect fail "a carriage return" "printf '%s\r\n' '$header' > App/Cr.swift" \
  "LICENSE HEADER VIOLATION: ./App/Cr.swift"
expect fail "another license id" "printf '// SPDX-License-Identifier: GPL-3.0-only\n' > App/Only.swift" \
  "LICENSE HEADER VIOLATION: ./App/Only.swift"
expect fail "a different case" "printf '// spdx-license-identifier: gpl-3.0-or-later\n' > App/Case.swift" \
  "LICENSE HEADER VIOLATION: ./App/Case.swift"
expect fail "a file named with a space" "printf 'import SwiftUI\n' > 'App/My Card.swift'" \
  "LICENSE HEADER VIOLATION: ./App/My Card.swift"
expect fail "a file in a nested App folder" "mkdir -p App/Nested && printf 'import SwiftUI\n' > App/Nested/Deep.swift" \
  "LICENSE HEADER VIOLATION: ./App/Nested/Deep.swift"
expect fail "a file under Tests without a header" "printf 'import Testing\n' > Tests/AnkyDomainTests/Missing.swift" \
  "LICENSE HEADER VIOLATION: ./Tests/AnkyDomainTests/Missing.swift"
expect fail "Package.swift without a header" "printf '// swift-tools-version: 6.0\n' > Package.swift" \
  "LICENSE HEADER VIOLATION: ./Package.swift"
expect fail "two bad files" "printf 'import Foundation\n' > App/One.swift && printf 'import Foundation\n' > Sources/AnkyDomain/Two.swift" \
  "LICENSE HEADER VIOLATION: ./App/One.swift
LICENSE HEADER VIOLATION: ./Sources/AnkyDomain/Two.swift"
expect fail "a root with no Swift file" "rm -rf App Sources Tests Package.swift" \
  "LICENSE HEADER VIOLATION: no Swift file under ."
expect fail "a root path that does not exist" ":" \
  "LICENSE HEADER VIOLATION: no Swift file under missing" missing

[ "$failures" = 0 ] && echo "check-license-headers tests: all passed"
exit "$failures"
