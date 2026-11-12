#!/bin/sh
# Fails when a piece declared under App/Design has no entry in App/Design/README.md, or an entry names no piece, so the
# catalog that workers read before building UI cannot go stale.
root=${1:-.}
design="$root/App/Design"
catalog="$design/README.md"
fail=0
violation() { echo "UI CATALOG VIOLATION: $1" && fail=1; }

if [ ! -f "$catalog" ]; then
  violation "App/Design/README.md is missing, it lists the pieces under App/Design"
  exit 1
fi

# A piece is read from its declaration line, so a declaration split over lines is not seen. A line's trailing // comment
# is not code, so it is cut before the match. A piece is never private, so those lines are dropped.
non_private() { grep -vE "(^|[^A-Za-z0-9_])(private|fileprivate)([^A-Za-z0-9_]|\$)"; }

# usage: block <type or extension header>   prints from its first line to the closing brace in column 0
block() { sed -En "/^$1([[:space:]{:]|\$)/,/^}/p"; }

# usage: members <keyword regex>   prints the name each 4-space-indented line declares with that keyword
members() {
  grep -E "^    ([^[:space:]()][^()]*[[:space:]])?($1)[[:space:]]+[A-Za-z_]" | non_private \
    | sed -E "s/^    ([^[:space:]()][^()]*[[:space:]])?($1)[[:space:]]+//" | sed -E "s/^([A-Za-z_][A-Za-z0-9_]*).*/\\1/"
}

# usage: pieces_of <swift file>
pieces_of() {
  code=$(sed 's://.*$::' "$1")
  types="(@?[A-Za-z]+[[:space:]]+)*(struct|enum|class)[[:space:]]+"
  printf '%s\n' "$code" | grep -E "^$types[A-Za-z_]" | non_private \
    | sed -E "s/^$types//" | sed -E "s/^([A-Za-z_][A-Za-z0-9_]*).*/\\1/"
  printf '%s\n' "$code" | block "extension View" | members "func"
  for holder in "enum Spacing" "enum Corner" "extension Color" "extension Shape"; do
    printf '%s\n' "$code" | block "$holder" | members "static (let|var)"
  done
}

pieces=$(for file in "$design"/*.swift; do [ -f "$file" ] && pieces_of "$file"; done | sort -u)

# Only a line that starts with a backticked name is an entry, so a rule or other prose names things freely.
entries=$(sed -En 's/^(### |- )`([A-Za-z_][A-Za-z0-9_]*)`.*/\2/p' "$catalog" | sort -u)

for name in $pieces; do
  echo "$entries" | grep -qxF "$name" \
    || violation "piece \`$name\` under App/Design has no entry in App/Design/README.md"
done
for name in $entries; do
  echo "$pieces" | grep -qxF "$name" \
    || violation "entry \`$name\` in App/Design/README.md names no piece under App/Design"
done

exit $fail
