#!/bin/sh
# Proves check-card-gone.sh fails when the old Check In card's texts are under App/ and passes everywhere else.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree> [root]
# The tree's folder name holds a space, so every case also proves the check quotes its root. With root ".", the check
# runs from inside the tree.
expect() {
  want=$1 desc=$2 setup=$3 root=${4:-}
  tree=$(mktemp -d "${TMPDIR:-/tmp}/card gone.XXXXXX")
  mkdir -p "$tree/App"
  printf 'import SwiftUI\n' > "$tree/App/AnkyApp.swift"
  (cd "$tree" && eval "$setup")
  if [ "$root" = "." ]; then
    (cd "$tree" && "$here/check-card-gone.sh" .) > /dev/null 2>&1 && got=pass || got=fail
  else
    "$here/check-card-gone.sh" "$tree" > /dev/null 2>&1 && got=pass || got=fail
  fi
  if [ "$got" != "$want" ]; then echo "FAIL: $desc (wanted $want, got $got)"; failures=$((failures + 1)); fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" ":"
expect fail "the question in a Swift file" "echo 'let t = \"How is your pain now?\"' > App/Card.swift"
expect fail "the action in a Swift file" "echo 'let t = \"Log pain\"' > App/Card.swift"
expect fail "the question in the String Catalog" "echo '\"How is your pain now?\" : {' > App/Localizable.xcstrings"
expect fail "the action in the String Catalog" "echo '\"Log pain\" : {' > App/Localizable.xcstrings"
expect fail "a text in a nested folder" "mkdir -p App/Today && echo 'let t = \"Log pain\"' > App/Today/Row.swift"
expect fail "a string that contains a text" "echo 'let t = \"Log pain now\"' > App/Row.swift"
expect pass "a text outside App" "mkdir -p Sources/AnkyDomain && echo 'let t = \"Log pain\"' > Sources/AnkyDomain/Row.swift"
expect pass "a text in a file that is no Swift or catalog" "echo 'Log pain' > App/Notes.md"
expect pass "a clean tree, run from inside it with root ." ":" "."
expect fail "a text, run from inside the tree with root ." "echo 'let t = \"Log pain\"' > App/Stray.swift" "."

[ "$failures" = 0 ] && echo "check-card-gone tests: all passed"
exit "$failures"
