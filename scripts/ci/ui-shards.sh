#!/bin/sh
# Lists the UI test classes from Tests/AnkyUITests, packs them into shards for the nightly's matrix, and checks that
# every class is in exactly one shard, so a class added tomorrow joins a shard with no workflow edit.
#
#   ui-shards.sh classes          the class names, sorted, one per line
#   ui-shards.sh matrix <count>   one line of JSON, {"include":[{"shard":1,"classes":"A B C"}]}
#   ui-shards.sh check <count>    exit 0 when the cover is exact, else one line for each problem
#
# UI_TESTS_DIR points the script at another folder of tests. UI_SHARDS_MATRIX_FILE makes check read the shards from a
# file in the matrix format instead of computing them.
here=$(cd "$(dirname "$0")" && pwd)
tests_dir=${UI_TESTS_DIR:-$here/../../Tests/AnkyUITests}
export LC_ALL=C

usage() {
  echo "usage: ui-shards.sh classes | matrix <count> | check <count>" >&2
  exit 2
}

# usage: scan
# Prints "class <weight> <name>" for each class declared as `final class <Name>: XCTestCase`, its weight the count of
# `func test` lines up to the next class, and "stray <file> <reason>" for each file whose tests the declarations miss.
scan() {
  awk '
    function file_of(path,   parts, n) { n = split(path, parts, "/"); return parts[n] }
    FNR == 1 { current = ""; files[++file_count] = FILENAME }
    /^[ \t]*final class [A-Za-z0-9_]+: XCTestCase([ \t{,]|$)/ {
      line = $0
      sub(/^[ \t]*final class /, "", line)
      sub(/:.*/, "", line)
      current = line
      if (!(current in weight)) { weight[current] = 0; order[++class_count] = current }
      matched[FILENAME]++
      next
    }
    /^[ \t]*((public|internal|open|private|fileprivate) )*(final )?class [A-Za-z0-9_]+[ \t]*:/ {
      current = ""
      odd[FILENAME]++
      next
    }
    /func test/ {
      tests[FILENAME]++
      if (current != "") weight[current]++
    }
    END {
      for (i = 1; i <= class_count; i++) print "class", weight[order[i]], order[i]
      for (i = 1; i <= file_count; i++) {
        f = files[i]
        if (!tests[f]) continue
        if (!matched[f]) print "stray", file_of(f), "holds func test but declares no final class Name: XCTestCase"
        else if (odd[f]) print "stray", file_of(f), "declares a class that does not name XCTestCase directly"
      }
    }
  ' "$tests_dir"/*.swift
}

has_test_files() {
  ls "$tests_dir"/*.swift > /dev/null 2>&1
}

class_lines() {
  scan | sed -n 's/^class //p'
}

classes() {
  if ! has_test_files; then
    echo "ui-shards: no test files in $tests_dir" >&2
    exit 1
  fi
  class_lines | awk '{ print $2 }' | sort
}

# usage: matrix_json <count>
# Greedy and longest first: each class, heaviest first and by name among equals, goes to the lightest shard.
matrix_json() {
  class_lines | sort -k1,1nr -k2,2 | awk -v count="$1" '
    {
      lightest = 1
      for (s = 2; s <= count; s++) if (load[s] < load[lightest]) lightest = s
      load[lightest] += $1
      members[lightest] = members[lightest] (members[lightest] == "" ? "" : " ") $2
    }
    END {
      printf "{\"include\":["
      separator = ""
      for (s = 1; s <= count; s++) {
        if (members[s] == "") continue
        printf "%s{\"shard\":%d,\"classes\":\"%s\"}", separator, s, members[s]
        separator = ","
      }
      print "]}"
    }
  '
}

# usage: shard_lines <matrix json>
# Prints "<shard> <class> <class> ..." for each entry, the shard number alone when its classes are empty.
shard_lines() {
  printf '%s\n' "$1" | grep -o '"shard":[0-9]*,"classes":"[^"]*"' |
    sed 's/^"shard":\([0-9]*\),"classes":"\(.*\)"$/\1 \2/'
}

# usage: cover_problems <class names> <shard lines>
cover_problems() {
  printf '%s\n' "$2" | awk -v want="$1" '
    BEGIN { n = split(want, names, " "); for (i = 1; i <= n; i++) known[names[i]] = 1 }
    {
      for (i = 2; i <= NF; i++) {
        seen[$i]++
        where[$i] = where[$i] (where[$i] == "" ? "" : ", ") $1
      }
      if (NF == 1) empty[++empty_count] = $1
    }
    END {
      for (i = 1; i <= n; i++) {
        c = names[i]
        if (!(c in seen)) { missing++; print "class " c " is in no shard" }
        else if (seen[c] > 1) print "class " c " is in " seen[c] " shards: " where[c]
      }
      for (c in seen) if (!(c in known)) print "shard " where[c] " names " c ", which is not a test class"
      for (i = 1; i <= empty_count; i++) {
        if (missing) print "shard " empty[i] " is empty while " missing " classes are in no shard"
      }
    }
  ' | sort
}

check() {
  if ! has_test_files; then
    echo "ui-shards: no test files in $tests_dir"
    return 1
  fi
  if [ -n "$UI_SHARDS_MATRIX_FILE" ]; then json=$(cat "$UI_SHARDS_MATRIX_FILE"); else json=$(matrix_json "$1"); fi
  problems=$(
    scan | sed -n 's/^stray \([^ ]*\) /\1: /p'
    cover_problems "$(classes | tr '\n' ' ')" "$(shard_lines "$json")"
  )
  [ -z "$problems" ] && return 0
  printf '%s\n' "$problems" | sed 's/^/ui-shards: /'
  return 1
}

needs_count() {
  case "$1" in '' | *[!0-9]* | 0*) usage ;; esac
}

matrix() {
  has_test_files || { echo "ui-shards: no test files in $tests_dir" >&2; exit 1; }
  matrix_json "$1"
}

[ $# -ge 1 ] || usage
case "$1" in
  classes) [ $# -eq 1 ] || usage; classes ;;
  matrix) [ $# -eq 2 ] || usage; needs_count "$2"; matrix "$2" ;;
  check) [ $# -eq 2 ] || usage; needs_count "$2"; check "$2" ;;
  *) usage ;;
esac
