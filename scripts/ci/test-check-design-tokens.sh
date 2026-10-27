#!/bin/sh
# Proves check-design-tokens.sh fails on a numeric corner radius under App/ and passes everywhere the rule allows.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree>
expect() {
  want=$1 desc=$2 setup=$3
  tree=$(mktemp -d)
  mkdir -p "$tree/App"
  printf 'import SwiftUI\n' > "$tree/App/AnkyApp.swift"
  (cd "$tree" && eval "$setup")
  if "$here/check-design-tokens.sh" "$tree" > /dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then echo "FAIL: $desc (wanted $want, got $got)"; failures=$((failures + 1)); fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" ":"
expect fail "a rounded rectangle with a number" "echo 'let s = RoundedRectangle(cornerRadius: 16)' > App/Card.swift"
expect fail "a rect shape with a number" "echo 'let s = Color.red.clipShape(.rect(cornerRadius: 12))' > App/Card.swift"
expect fail "the cornerRadius modifier with a number" "echo 'let v = Text(\"a\").cornerRadius(8)' > App/Badge.swift"
expect fail "an uneven corner with a number" "echo 'let s = UnevenRoundedRectangle(topLeadingRadius: 16)' > App/Tab.swift"
expect fail "a number in a nested folder" "mkdir -p App/Today && echo 'let s = RoundedRectangle(cornerRadius: 16)' > App/Today/Row.swift"
expect pass "a capsule" "echo 'let s = Capsule()' > App/Pill.swift"
expect pass "the shared card shape" "echo 'let v = Text(\"a\").background(Color(\"CardBackground\"), in: .card)' > App/Card.swift"
expect pass "the named card radius outside App/Design" "echo 'let s = RoundedRectangle(cornerRadius: Corner.card)' > App/Card.swift"
expect pass "a number inside App/Design" "mkdir -p App/Design && echo 'let s = RoundedRectangle(cornerRadius: 22)' > App/Design/Corner.swift"
expect pass "a number outside App" "mkdir -p Sources/AnkyDomain && echo 'let s = RoundedRectangle(cornerRadius: 16)' > Sources/AnkyDomain/Shape.swift"

[ "$failures" = 0 ] && echo "check-design-tokens tests: all passed"
exit "$failures"
