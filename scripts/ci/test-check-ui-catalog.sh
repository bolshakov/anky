#!/bin/sh
# Proves check-ui-catalog.sh fails when App/Design and its catalog name different pieces, and passes when they match.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: swift_file <name> <line>...
swift_file() {
  mkdir -p App/Design
  name=$1
  shift
  printf '%s\n' "$@" > "App/Design/$name"
}

# usage: catalog <name>...   one entry line for each name, under a Rules section with a rule bullet
catalog() {
  mkdir -p App/Design
  {
    printf '## Rules\n\n- A screen takes no raw colour.\n\n## Pieces\n\n'
    for name in "$@"; do printf -- '- `%s`: when to use it.\n' "$name"; done
  } > App/Design/README.md
}

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree> [text a failing run prints]
expect() {
  want=$1 desc=$2 setup=$3 needle=$4
  tree=$(mktemp -d)
  (cd "$tree" && eval "$setup")
  out=$("$here/check-ui-catalog.sh" "$tree" 2>&1) && got=pass || got=fail
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc (wanted $want, got $got)"
    failures=$((failures + 1))
  elif [ "$want" = pass ] && [ -n "$out" ]; then
    echo "FAIL: $desc (a passing run printed: $out)"
    failures=$((failures + 1))
  elif [ -n "$needle" ] && ! echo "$out" | grep -q "UI CATALOG VIOLATION:.*$needle"; then
    echo "FAIL: $desc (no violation line names $needle, got: $out)"
    failures=$((failures + 1))
  fi
  rm -rf "${tree:?}"
}

# Rule: the script compares both ways.
expect pass "a matching tree" \
  'swift_file Row.swift "struct Row: View {}" && catalog Row'
expect pass "an empty design folder and a catalog with no entry" \
  'mkdir -p App/Design && catalog'
expect fail "a missing catalog" \
  'swift_file Row.swift "struct Row: View {}"' "README.md"
expect fail "a missing design folder" \
  'mkdir -p App' "README.md"

# Rule: the script fails on a piece with no catalog entry.
expect fail "a struct with no entry" \
  'swift_file Row.swift "struct IconRow<Trailing: View>: View {}" && catalog Row' "IconRow"
expect fail "an enum with no entry" \
  'swift_file Row.swift "enum Corner {}" "struct Row {}" && catalog Row' "Corner"
expect fail "a class with no entry" \
  'swift_file Row.swift "final class Store {}" "struct Row {}" && catalog Row' "Store"
expect fail "a modifier in an extension View with no entry" \
  'swift_file Row.swift "extension View {" "    func cardCaption() -> some View { self }" "}" && catalog' "cardCaption"
expect fail "a modifier in an extension View where clause with no entry" \
  'swift_file Row.swift "extension View where Self: Sendable {" "    func cardCaption() -> some View { self }" "}" && catalog' "cardCaption"
expect fail "a modifier after another type in the same file with no entry" \
  'swift_file Row.swift "struct Row {}" "extension View {" "    func cardCaption() -> some View { self }" "}" && catalog Row' "cardCaption"
expect fail "a Spacing token with no entry" \
  'swift_file Spacing.swift "enum Spacing {" "    static let blockGap: CGFloat = 32" "}" && catalog Spacing' "blockGap"
expect fail "a Corner token with no entry" \
  'swift_file Corner.swift "enum Corner {" "    static let iconTile: CGFloat = 9" "}" && catalog Corner' "iconTile"
expect fail "a colour token with no entry" \
  'swift_file Color.swift "extension Color {" "    static var surface: Color { Color(\"Surface\") }" "}" && catalog' "surface"
expect fail "a colour token declared with let and no entry" \
  'swift_file Color.swift "extension Color {" "    static let surface = Color(\"Surface\")" "}" && catalog' "surface"
expect fail "a Shape token with no entry" \
  'swift_file Corner.swift "extension Shape where Self == RoundedRectangle {" "    static var card: RoundedRectangle { .rect }" "}" && catalog' "card"
expect fail "a second struct in the same file with no entry" \
  'swift_file Row.swift "struct Row {}" "struct Other {}" && catalog Row' "Other"
expect fail "a piece whose entry names it with a dot" \
  'swift_file Spacing.swift "enum Spacing {" "    static let blockGap: CGFloat = 32" "}" && catalog Spacing Spacing.blockGap' "blockGap"
expect fail "a piece declared after a private one" \
  'swift_file Row.swift "private struct Hidden {}" "struct Shown {}" && catalog' "Shown"
expect fail "a piece declared with a trailing comment on another line" \
  'swift_file Row.swift "// struct Old {}" "struct New {} // was Old" && catalog Old' "New"

# Rule: the script fails on an entry with no piece.
expect fail "an entry with no piece" \
  'swift_file Row.swift "struct Row {}" && catalog Row NoSuchPiece' "NoSuchPiece"
expect fail "an entry left behind after a piece is renamed" \
  'swift_file Row.swift "struct TodayRow {}" && catalog Row' "\`Row\` in"
expect fail "the renamed piece is named too" \
  'swift_file Row.swift "struct TodayRow {}" && catalog Row' "\`TodayRow\` under"
expect fail "an entry for a piece that only a comment declares" \
  'swift_file Row.swift "struct Row {}" "// struct Old {}" && catalog Row Old' "Old"
expect fail "an entry with no design folder files" \
  'mkdir -p App/Design && catalog Row' "Row"
expect fail "an entry for a function that is not in an extension View" \
  'swift_file Row.swift "struct Row {" "    func body() {}" "}" && catalog Row body' "body"
expect fail "an entry for a static member of a type that holds no tokens" \
  'swift_file Row.swift "struct Row {" "    static let gap: CGFloat = 1" "}" && catalog Row gap' "gap"
expect fail "an entry for a function in another extension" \
  'swift_file Row.swift "struct Row {}" "extension Text {" "    func bold2() -> Text { self }" "}" && catalog Row bold2' "bold2"

# Rule: pieces that share a bare name take one entry line.
expect pass "a Spacing token and a View modifier called rowHeight share one entry" \
  'swift_file Spacing.swift "enum Spacing {" "    static let rowHeight: CGFloat = 52" "}" && swift_file RowHeight.swift "extension View {" "    func rowHeight(_ height: CGFloat = Spacing.rowHeight) -> some View { self }" "}" && catalog Spacing rowHeight'
expect pass "a Spacing token and a View modifier called emptyBlockGap share one entry" \
  'swift_file Spacing.swift "enum Spacing {" "    static let emptyBlockGap: CGFloat = 96" "}" && swift_file Screen.swift "extension View {" "    func emptyBlockGap() -> some View { self }" "}" && catalog Spacing emptyBlockGap'
expect pass "a Color, Corner and Shape token called card share one entry" \
  'swift_file Color.swift "extension Color {" "    static var card: Color { Color(\"Card\") }" "}" && swift_file Corner.swift "enum Corner {" "    static let card: CGFloat = 22" "}" "extension Shape where Self == RoundedRectangle {" "    static var card: RoundedRectangle { .rect }" "}" && catalog Corner card'
expect pass "two entry lines for one name" \
  'swift_file Row.swift "struct Row {}" && catalog Row Row'
expect fail "a shared name with no entry" \
  'swift_file Spacing.swift "enum Spacing {" "    static let rowHeight: CGFloat = 52" "}" && swift_file RowHeight.swift "extension View {" "    func rowHeight() -> some View { self }" "}" && catalog Spacing' "rowHeight"

# Rule: a private declaration is not a piece.
expect pass "a private struct with no entry" \
  'swift_file Row.swift "private struct RowHeight: ViewModifier {}" && catalog'
expect pass "a fileprivate struct with no entry" \
  'swift_file Row.swift "fileprivate struct RowHeight: ViewModifier {}" && catalog'
expect pass "a private enum and class with no entry" \
  'swift_file Row.swift "private enum Mode {}" "private final class Cache {}" && catalog'
expect pass "a private modifier in an extension View with no entry" \
  'swift_file Row.swift "extension View {" "    private func hidden() -> some View { self }" "}" && catalog'
expect pass "a fileprivate modifier in an extension View with no entry" \
  'swift_file Row.swift "extension View {" "    fileprivate func hidden() -> some View { self }" "}" && catalog'
expect pass "a private modifier next to a shared one" \
  'swift_file Row.swift "extension View {" "    private func hidden() -> some View { self }" "    func shown() -> some View { self }" "}" && catalog shown'
expect pass "a private Spacing token with no entry" \
  'swift_file Spacing.swift "enum Spacing {" "    private static let base: CGFloat = 8" "    static let gap: CGFloat = 8" "}" && catalog Spacing gap'
expect pass "a fileprivate colour token with no entry" \
  'swift_file Color.swift "extension Color {" "    fileprivate static var raw: Color { Color(\"Raw\") }" "}" && catalog'
expect fail "an entry for a private piece" \
  'swift_file Row.swift "private struct RowHeight: ViewModifier {}" && catalog RowHeight' "RowHeight"

# What a piece is not.
expect pass "a method of a view struct is no piece" \
  'swift_file Row.swift "struct Row: View {" "    var body: some View { Text(\"a\") }" "    func row(chevron: Bool) -> some View { self }" "}" && catalog Row'
expect pass "a function in an extension of another type is no piece" \
  'swift_file Row.swift "extension Text {" "    func bold2() -> Text { self }" "}" && catalog'
expect pass "a static member of a view struct is no piece" \
  'swift_file Row.swift "struct Row {" "    static let gap: CGFloat = 1" "}" && catalog Row'
expect pass "a function nested in a modifier is no piece" \
  'swift_file Row.swift "extension View {" "    func shown() -> some View {" "        func inner() {}" "        return self" "    }" "}" && catalog shown'
expect pass "a declaration in a trailing comment is no piece" \
  'swift_file Row.swift "struct Row {} // struct Old {}" && catalog Row'
expect pass "a declaration on a comment line is no piece" \
  'swift_file Row.swift "struct Row {}" "// struct Old {}" "    // func gone() {}" && catalog Row'
expect pass "a backslash n in a string literal does not start a new line" \
  'swift_file Row.swift "struct Row {}" "let text = \"a\\nstruct Old {}\"" && catalog Row'
expect pass "a nested type inside a piece is no piece" \
  'swift_file Row.swift "struct Row {" "    struct Inner {}" "    enum Mode {}" "}" && catalog Row'
expect pass "a type name that only starts like a keyword is no piece" \
  'swift_file Row.swift "struct Row {}" "structure Old {}" "classic Old2 {}" && catalog Row'
expect pass "a member after an extension that closes is no piece" \
  'swift_file Row.swift "extension View {" "    func shown() -> some View { self }" "}" "struct Row {" "    func hidden() {}" "}" && catalog shown Row'
expect pass "a Spacing token after another type in the file" \
  'swift_file Spacing.swift "struct Row {}" "enum Spacing {" "    static let gap: CGFloat = 8" "}" && catalog Row Spacing gap'

# Rule: only an entry line is read from the catalog.
expect pass "a rule bullet that names a backticked word outside App/Design" \
  'swift_file Row.swift "struct Row {}" && mkdir -p App/Design && printf "## Rules\n\n- A screen never sets \`navigationBarTitleDisplayMode\`.\n\n## Pieces\n\n- \`Row\`: x\n" > App/Design/README.md'
expect pass "a prose bullet outside Rules that does not start with a backticked name" \
  'swift_file Row.swift "struct Row {}" && mkdir -p App/Design && printf "## Pieces\n\n- Use \`Row\` for a row, not \`List\`.\n- \`Row\`: x\n" > App/Design/README.md'
expect fail "a rule bullet that starts with a backticked name is an entry" \
  'swift_file Row.swift "struct Row {}" && mkdir -p App/Design && printf "## Rules\n\n- \`Section\` never takes a footer.\n\n## Pieces\n\n- \`Row\`: x\n" > App/Design/README.md' "Section"
expect pass "an entry written as a level-3 heading" \
  'swift_file Row.swift "struct Row {}" && mkdir -p App/Design && printf "## Rules\n\n## Pieces\n\n### \`Row\`\n\nWhen to use it.\n" > App/Design/README.md'
expect pass "entries under several level-2 headings after Rules" \
  'swift_file Row.swift "struct Row {}" "struct Card {}" && mkdir -p App/Design && printf "## Rules\n\n- r\n\n## Rows\n\n- \`Row\`: x\n\n## Cards\n\n- \`Card\`: x\n" > App/Design/README.md'
expect pass "an entry below the Rules section, at the end of the file" \
  'swift_file Row.swift "struct Row {}" "struct Pad {}" && mkdir -p App/Design && printf "## Pieces\n\n- \`Row\`: x\n\n## Rules\n\n- r\n- \`Pad\`: x\n" > App/Design/README.md'
expect pass "an entry line with text after the name" \
  'swift_file Row.swift "struct Row {}" && mkdir -p App/Design && printf "## Rules\n\n## Pieces\n\n- \`Row\`: use it, not a hand-built \`HStack\`.\n" > App/Design/README.md'

# The root argument and the default.
tree=$(mktemp -d)
(cd "$tree" && swift_file Row.swift "struct Row {}" && catalog Row)
if ! (cd "$tree" && "$here/check-ui-catalog.sh" > /dev/null 2>&1); then
  echo "FAIL: the default root is the current folder (wanted pass)"
  failures=$((failures + 1))
fi
(cd "$tree" && catalog)
if (cd "$tree" && "$here/check-ui-catalog.sh" > /dev/null 2>&1); then
  echo "FAIL: the default root is the current folder (wanted fail)"
  failures=$((failures + 1))
fi
rm -rf "${tree:?}"

[ "$failures" = 0 ] && echo "check-ui-catalog tests: all passed"
exit "$failures"
