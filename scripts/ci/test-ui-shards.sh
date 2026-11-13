#!/bin/sh
# Proves ui-shards.sh puts every UI test class in exactly one shard, and that check fails with a line that names the
# problem when a class is dropped, repeated, unmatched or unknown.
here=$(cd "$(dirname "$0")" && pwd)
shards="$here/ui-shards.sh"
repo=$(cd "$here/../.." && pwd)
failures=0
work=$(mktemp -d)
trap 'rm -rf "${work:?}"' EXIT

pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# usage: expect_equal <description> <wanted> <got>
expect_equal() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (wanted '$2', got '$3')"; fi
}

# usage: new_tree <name>, which makes an empty tests folder and sets $tree to it
new_tree() {
  tree="$work/$1"
  mkdir -p "$tree/Support"
}

# usage: add_class <name> <tests> [file]
# Writes `final class <name>: XCTestCase` with that many test methods to <file>, default <name>.swift, in $tree.
add_class() {
  {
    echo "final class $1: XCTestCase {"
    n=0
    while [ "$n" -lt "$2" ]; do
      echo "  func testCase$n() {}"
      n=$((n + 1))
    done
    echo "}"
  } >> "$tree/${3:-$1.swift}"
}

# usage: matrix <count>, over $tree
matrix() { UI_TESTS_DIR=$tree "$shards" matrix "$1"; }

# usage: words_of_matrix <json>, prints each class once per appearance, sorted
words_of_matrix() {
  printf '%s\n' "$1" | grep -o '"classes":"[^"]*"' | sed 's/"classes":"//; s/"$//' | tr ' ' '\n' | sort
}

# usage: expect_check_fails <description> <count> <text the output must contain> [matrix file]
expect_check_fails() {
  out=$(UI_TESTS_DIR=$tree UI_SHARDS_MATRIX_FILE=$4 "$shards" check "$2" 2>&1)
  code=$?
  lines=$(printf '%s\n' "$out" | grep -c '^ui-shards: ')
  if [ "$code" = 1 ] && [ "$lines" -ge 1 ] && printf '%s\n' "$out" | grep -qF "$3"; then pass "$1"
  else fail "$1 (wanted exit 1 and a line with '$3', got exit $code: $out)"; fi
}

# usage: expect_check_passes <description> <count> [matrix file]
expect_check_passes() {
  out=$(UI_TESTS_DIR=$tree UI_SHARDS_MATRIX_FILE=$3 "$shards" check "$2" 2>&1)
  code=$?
  if [ "$code" = 0 ] && [ -z "$out" ]; then pass "$1"; else fail "$1 (wanted exit 0 and no output, got exit $code: $out)"; fi
}

# The real tree: every class is in exactly one shard.
real_classes=$("$shards" classes)
if [ -n "$real_classes" ]; then pass "the real tree lists classes"; else fail "the real tree lists no class"; fi
expect_equal "the real classes are sorted" "$(printf '%s\n' "$real_classes" | sort)" "$real_classes"
real_matrix=$("$shards" matrix 10)
expect_equal "the real matrix holds each real class once" "$real_classes" "$(words_of_matrix "$real_matrix")"
if "$shards" check 10 > /dev/null 2>&1; then pass "the real tree's check passes"; else fail "the real tree's check fails"; fi
expect_equal "the real matrix starts at shard 1" 1 "$(printf '%s\n' "$real_matrix" | grep -o '"shard":[0-9]*' | head -n 1 | tr -dc 0-9)"
# The script finds the tests from its own location, whatever the current folder is.
expect_equal "classes run from another folder" "$real_classes" "$(cd "$work" && "$shards" classes)"
for f in "$repo"/Tests/AnkyUITests/*.swift; do
  if grep -q 'func test' "$f" && ! grep -q '^[[:space:]]*final class [A-Za-z0-9_]*: XCTestCase' "$f"; then
    fail "the real file $(basename "$f") holds tests the script cannot see"
  fi
done

# Rule: a class added gets into one shard, and the check passes.
new_tree add
add_class AlphaTests 3
add_class BetaTests 2
before=$(matrix 2 | grep -c NewProbeTests)
expect_equal "a class not yet added is in no shard" 0 "$before"
add_class NewProbeTests 1
after=$(matrix 2)
expect_equal "an added class is in exactly one shard" 1 "$(words_of_matrix "$after" | grep -c '^NewProbeTests$')"
expect_check_passes "check passes with the added class" 2

# Packing: heaviest first, each class to the lightest shard, ties by class name, the same on every run.
new_tree packing
add_class AlphaTests 3
add_class DeltaTests 1
add_class CharlieTests 2
add_class BravoTests 2
wanted='{"include":[{"shard":1,"classes":"AlphaTests DeltaTests"},{"shard":2,"classes":"BravoTests CharlieTests"}]}'
expect_equal "greedy longest-first packing" "$wanted" "$(matrix 2)"
expect_equal "packing is the same on a second run" "$(matrix 2)" "$(matrix 2)"

# Review Focus: more shards than classes, and a count that does not divide the classes.
new_tree few
add_class AlphaTests 1
add_class BetaTests 1
add_class GammaTests 1
many=$(matrix 10)
expect_equal "more shards than classes leaves no empty shard" 3 "$(printf '%s\n' "$many" | grep -o '"shard":' | wc -l | tr -d ' ')"
expect_equal "more shards than classes drops no class" "$(UI_TESTS_DIR=$tree "$shards" classes)" "$(words_of_matrix "$many")"
if printf '%s\n' "$many" | grep -q '"classes":""'; then fail "more shards than classes gives an empty classes entry"; else pass "no empty classes entry"; fi
expect_check_passes "check passes with more shards than classes" 10
new_tree indivisible
for name in AlphaTests BetaTests GammaTests DeltaTests EpsilonTests; do add_class "$name" 1; done
odd=$(matrix 2)
expect_equal "a count that does not divide drops no class" "$(UI_TESTS_DIR=$tree "$shards" classes)" "$(words_of_matrix "$odd")"
expect_check_passes "check passes when the count does not divide" 2
expect_equal "one shard holds every class" 5 "$(words_of_matrix "$(matrix 1)" | wc -l | tr -d ' ')"

# Class extraction.
new_tree names
add_class NoteTests 1
add_class ScaleNoteTests 1
printf 'final class Support: XCTestCase {\n  func testNever() {}\n}\n' > "$tree/Support/Helper.swift"
expect_equal "a class whose name starts another's is listed beside it" "NoteTests
ScaleNoteTests" "$(UI_TESTS_DIR=$tree "$shards" classes)"
expect_equal "a class under Support is not listed" 0 "$(UI_TESTS_DIR=$tree "$shards" classes | grep -c '^Support$')"
new_tree two
add_class AlphaTests 3 Both.swift
add_class BetaTests 1 Both.swift
expect_equal "a file with two classes lists both" "AlphaTests
BetaTests" "$(UI_TESTS_DIR=$tree "$shards" classes)"
expect_equal "each class of a file with two weighs only its own tests" \
  '{"include":[{"shard":1,"classes":"AlphaTests"},{"shard":2,"classes":"BetaTests"}]}' "$(matrix 2)"
expect_check_passes "check passes for a file with two classes" 2

# Rule: check fails, and names the problem, for each way the cover can be wrong.
new_tree cover
add_class AlphaTests 3
add_class BetaTests 2
add_class GammaTests 1
good=$(matrix 2)
dropped="$work/dropped.json"
printf '%s\n' "$good" | sed 's/ \{0,1\}GammaTests//' > "$dropped"
expect_check_fails "a class dropped from a shard" 2 "class GammaTests is in no shard" "$dropped"
twice="$work/twice.json"
printf '%s\n' "$good" | sed 's/"classes":"AlphaTests/"classes":"AlphaTests BetaTests/' > "$twice"
expect_check_fails "a class in two shards" 2 "class BetaTests is in 2 shards" "$twice"
repeated="$work/repeated.json"
printf '%s\n' "$good" | sed 's/"classes":"AlphaTests/"classes":"AlphaTests AlphaTests/' > "$repeated"
expect_check_fails "a class twice in one shard" 2 "class AlphaTests is in 2 shards" "$repeated"
unknown="$work/unknown.json"
printf '%s\n' "$good" | sed 's/GammaTests/GammaTests GhostTests/' > "$unknown"
expect_check_fails "a shard that names a class the tests lack" 2 "GhostTests, which is not a test class" "$unknown"
emptied="$work/emptied.json"
printf '{"include":[{"shard":1,"classes":"AlphaTests BetaTests"},{"shard":2,"classes":""}]}\n' > "$emptied"
expect_check_fails "an empty shard while a class is in no shard" 2 "shard 2 is empty while 1 classes are in no shard" "$emptied"
expect_check_fails "a class left out names only that class" 2 "GammaTests" "$emptied"
none="$work/none.json"
echo '{"include":[]}' > "$none"
expect_check_fails "a matrix with no shard" 2 "class AlphaTests is in no shard" "$none"

# Review Focus: a declaration the script cannot match is named, not dropped.
new_tree stray
add_class AlphaTests 1
printf 'import XCTest\nclass LooseTests: BaseTestCase {\n  func testLoose() {}\n}\n' > "$tree/Loose.swift"
expect_check_fails "a file with func test and no matched class" 2 "Loose.swift" ""
expect_check_fails "the stray file says what it lacks" 2 "no final class Name: XCTestCase" ""
new_tree indirect
printf 'final class AlphaTests: XCTestCase {\n  func testA() {}\n}\nfinal class BetaTests: BaseTestCase {\n  func testB() {}\n}\n' \
  > "$tree/Mixed.swift"
expect_check_fails "a second class that does not name XCTestCase beside a matched one" 2 "Mixed.swift" ""
new_tree helper
add_class AlphaTests 1
printf 'enum Helper {\n  static func testData() {}\n}\n' > "$tree/Helper.swift"
expect_check_fails "func test in a file with no class" 2 "Helper.swift" ""
new_tree notests
add_class AlphaTests 1
printf 'import XCTest\nstruct Plain {}\n' > "$tree/Plain.swift"
expect_check_passes "a file with no tests and no class is left alone" 1

# Arguments and an empty folder.
new_tree empty
if UI_TESTS_DIR=$tree "$shards" check 2 > /dev/null 2>&1; then fail "check passes with no test file"; else pass "check fails with no test file"; fi
if UI_TESTS_DIR=$tree "$shards" matrix 2 > /dev/null 2>&1; then fail "matrix succeeds with no test file"; else pass "matrix fails with no test file"; fi
for args in "" "matrix" "matrix 0" "matrix two" "check 0" "check -1" "check" "classes 3" "nothing"; do
  # shellcheck disable=SC2086
  "$shards" $args > /dev/null 2>&1
  code=$?
  if [ "$code" = 2 ]; then pass "usage error for '$args'"; else fail "wanted exit 2 for '$args', got $code"; fi
done

[ "$failures" = 0 ] && echo "ui-shards tests: all passed"
exit "$failures"
