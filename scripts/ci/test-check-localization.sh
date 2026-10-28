#!/bin/sh
# Proves check-localization.sh fails on text that skips the string catalog and passes on the shapes the app uses.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: expect <pass|fail> <description> <file> <swift line> [<declaration file> <declaration line>]...
expect() {
  want=$1 desc=$2 path=$3 line=$4
  shift 4
  tree=$(mktemp -d)
  mkdir -p "$tree/$(dirname "$path")"
  printf '%s\n' "$line" > "$tree/$path"
  while [ $# -gt 0 ]; do
    mkdir -p "$tree/$(dirname "$1")"
    printf '%s\n' "$2" > "$tree/$1"
    shift 2
  done
  if "$here/check-localization.sh" "$tree" > /dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then echo "FAIL: $desc (wanted $want, got $got)"; failures=$((failures + 1)); fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" App/Clean.swift 'import SwiftUI'
expect pass "a string literal" App/Today/Empty.swift 'Text("Nothing logged today")'
expect pass "an interpolated literal" App/NewEntry/Note.swift 'Text("\(count) left")'
expect pass "a literal with a comma and a parenthesis" App/Today/Empty.swift 'Text("Pain, mostly (on waking)")'
expect pass "a resource property" App/Today/Row.swift 'Text(entry.kind.displayName)' \
  App/Model/Kind.swift '    var displayName: LocalizedStringResource {'
expect pass "a resource from a function" App/NewEntry/Note.swift 'Text(counterText(counter))' \
  App/NewEntry/Counter.swift '    private func counterText(_ counter: Int) -> LocalizedStringResource {'
expect pass "a resource parameter" App/NewEntry/Kind.swift 'Text(title)' \
  App/NewEntry/Title.swift '    let title: LocalizedStringResource'
expect pass "a key parameter" App/NewEntry/Kind.swift 'Text(title)' \
  App/NewEntry/Title.swift '    let title: LocalizedStringKey'
expect pass "a date with a format" App/Today/Header.swift 'Text(Date.now, format: .dateTime.weekday(.wide))'
expect pass "a number with a format" App/Today/Row.swift 'Text(entry.severity.value, format: .number)'
expect pass "a number from a call with a format" App/Today/Row.swift 'Text(Double(count), format: .number)'
expect pass "a number from a nested call with a format" App/Today/Row.swift 'Text(abs(delta), format: .number)'
expect pass "a date from a method call with a format" App/Today/Header.swift \
  'Text(entry.date.addingTimeInterval(60), format: .dateTime)'
expect pass "a date from an initializer with a format" App/Today/Header.swift \
  'Text(Date(timeIntervalSince1970: 0), format: .dateTime)'
expect pass "a number from a call with a format wrapped onto the next line" App/Today/Row.swift 'Text(Double(count),
    format: .number)'
expect pass "a Text inside an accessibility value" App/Today/Row.swift 'Text("x").accessibilityValue(Text("x"))'
expect pass "a Text value passed to an accessibility value" App/NewEntry/Date.swift '.accessibilityValue(shownDate)' \
  App/NewEntry/Shown.swift '    private var shownDate: Text {'
expect pass "a resource passed to an accessibility label" App/NewEntry/Severity.swift \
  '.accessibilityLabel(severity.spokenValue)' \
  App/Model/Severity.swift '    var spokenValue: LocalizedStringResource {'
expect pass "a literal wrapped onto its own line" App/Today/Empty.swift 'Text(
    "Nothing logged today and the rest of the sentence runs on for a while")'
expect pass "a literal label wrapped onto its own line" App/Today/Row.swift '.accessibilityLabel(
    "Save the entry")'
expect pass "a resource wrapped onto its own line" App/Today/Row.swift 'Text(
    title)' \
  App/Today/Decl.swift '    let title: LocalizedStringResource'
expect pass "a date with a format wrapped onto its own lines" App/Today/Header.swift 'Text(
    Date.now,
    format: .dateTime.weekday(.wide)
)'
expect pass "a number with a format wrapped onto its own lines" App/Today/Row.swift 'Text(
    value,
    format: .number)'
expect pass "a date with a format that starts on the wrapped line" App/Today/Header.swift 'Text(Date.now,
    format: .dateTime.weekday(.wide))'
expect pass "a labeled argument" App/NewEntry/Kind.swift 'Button(action: select) {}'
expect pass "an image name" App/Today/Empty.swift 'Image(systemName: "pencil")'
expect pass "a color name" App/Today/Empty.swift 'Color("AccentColor")'
expect pass "an accessibility identifier" App/Today/Empty.swift '.accessibilityIdentifier("save-entry")'
expect pass "a UIKit string from the catalog" App/NewEntry/NoteTextView.swift \
  'placeholder.text = String(localized: "Add a note")'
expect pass "a UIKit copy of a string value" App/NewEntry/NoteTextView.swift 'view.text = text'
expect pass "a UIKit text comparison" App/NewEntry/NoteTextView.swift 'if label.text == "x" {'
expect pass "a TextField with a label" App/NewEntry/Note.swift 'TextField("Name", text: $name)'
expect pass "a violation only in a test" Tests/AnkyTests/Copy.swift 'Text(verbatim: "Today")'
expect pass "a violation only in Sources" Sources/AnkyDomain/Copy.swift 'let s = Text(verbatim: "x")'

expect fail "verbatim text" App/Today/TodayView.swift 'Text(verbatim: "Today")'
expect fail "a String variable" App/Today/Name.swift 'Text(name)' \
  App/Today/Decl.swift '    let name: String = "Today"'
expect fail "a call that returns a String" App/Today/Name.swift 'Text(makeLabel())' \
  App/Today/Decl.swift '    func makeLabel() -> String {'
expect fail "a String built by hand" App/Today/Name.swift 'Text(String(localized: "Today"))'
expect fail "a literal joined to a variable" App/Today/Name.swift 'Text("Today" + suffix)'
expect fail "a verbatim label wrapped onto its own line" App/Today/TodayView.swift 'Text(
    verbatim: "Today")'
expect fail "a String variable wrapped onto its own line" App/Today/Name.swift 'Text(
    name)' \
  App/Today/Decl.swift '    let name: String'
expect fail "a String followed by another argument on the next line" App/Today/Name.swift 'Button(title,
    role: .destructive) {}' \
  App/Today/Decl.swift '    let title: String'
expect fail "a date with no format on the next line" App/Today/Header.swift 'Text(Date.now,
    )'
expect fail "a String passed to a button" App/Today/Name.swift 'Button(title) {}' \
  App/Today/Decl.swift '    let title: String'
expect fail "a String passed to an accessibility label" App/Today/Name.swift '.accessibilityLabel(label)' \
  App/Today/Decl.swift '    let label: String'
expect fail "a String passed to a label" App/Today/Name.swift 'Label(name, systemImage: "x")' \
  App/Today/Decl.swift '    let name: String'
expect fail "a String passed to a navigation title" App/Today/Name.swift '.navigationTitle(name)' \
  App/Today/Decl.swift '    let name: String'
expect fail "a String passed to an accessibility value" App/Today/Name.swift '.accessibilityValue(name)' \
  App/Today/Decl.swift '    let name: String'
expect fail "a String passed to an accessibility hint" App/Today/Name.swift '.accessibilityHint(name)' \
  App/Today/Decl.swift '    let name: String'
expect fail "a name that is a resource in one file and a String in another" App/Today/Name.swift 'Text(title)' \
  App/Model/Kind.swift '    let title: LocalizedStringResource' \
  App/Today/Other.swift '    let title: String'
expect fail "a String button title with a formatted call later on the line" App/Today/Name.swift \
  'Button(title) { save(entry, format: .csv) }' \
  App/Today/Decl.swift '    let title: String'
expect fail "a UIKit text literal" App/NewEntry/NoteTextView.swift 'label.text = "Today"'
expect fail "a UIKit placeholder literal" App/NewEntry/NoteTextView.swift 'field.placeholder = "Add a note"'
expect fail "a UIKit accessibility label literal" App/NewEntry/NoteTextView.swift 'cell.accessibilityLabel = "Save"'
expect fail "a UIKit title literal" App/NewEntry/NoteTextView.swift 'item.title = "Today"'
expect fail "a UIKit accessibility hint literal" App/NewEntry/NoteTextView.swift 'hint.accessibilityHint = "Saves"'

tree=$(mktemp -d)
mkdir -p "$tree/App/Today"
printf '%s\n' 'import SwiftUI' 'Text(verbatim: "Today")' > "$tree/App/Today/TodayView.swift"
out=$("$here/check-localization.sh" "$tree")
got=$?
if [ "$got" != 1 ] || ! printf '%s\n' "$out" | grep -qx 'App/Today/TodayView.swift:2'
then echo "FAIL: a violation prints its file and line and exits 1 (exit $got)"; failures=$((failures + 1)); fi
if ! printf '%s\n' "$out" | grep -q '^LOCALIZATION VIOLATION: '
then echo "FAIL: a violation prints the LOCALIZATION VIOLATION line"; failures=$((failures + 1)); fi
rm -rf "${tree:?}"

[ "$failures" = 0 ] && echo "check-localization tests: all passed"
exit "$failures"
