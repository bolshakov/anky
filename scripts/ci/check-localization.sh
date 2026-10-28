#!/bin/sh
# Fails when text on screen skips the string catalog, so each new string needs a catalog entry.
root=${1:-.}
app="$root/App"

# The grep cannot see a type, so a bare name passes only when App/ declares it as a resource or a Text.
resources=$(grep -rhoE --include="*.swift" \
  '[[:alnum:]_]+(\([^)]*\))?[[:space:]]*(:|->)[[:space:]]*(LocalizedStringResource|LocalizedStringKey|Text)([^[:alnum:](]|$)' "$app" |
  sed -E 's/^([[:alnum:]_]+).*/\1/' | tr '\n' ' ')

hits=$(find "$app" -name '*.swift' -exec awk -v root="$root" -v resources="$resources" '
function allowed(rest, arg, name) {
  if (rest ~ /^"([^"\\]|\\.)*"([,)]|[[:space:]]*$)/ || rest ~ /^(Text\(|LocalizedString)/) return 1
  if (rest ~ /^[[:alnum:]_]+:/ && rest !~ /^verbatim:/) return 1
  arg = rest
  sub(/[,)].*/, "", arg)
  if (substr(rest, length(arg) + 1) ~ /^, format:/) return 1
  name = arg
  sub(/\(.*/, "", name)
  sub(/.*\./, "", name)
  return name != "" && index(" " resources " ", " " name " ") > 0
}
function judge(rest) {
  if (rest ~ /^[^,)]*,[[:space:]]*$/) {
    waiting = 1
    waitbad = !allowed(rest)
  } else if (!allowed(rest)) bad = 1
}
{
  if (FNR == 1) open = waiting = 0
  bad = $0 ~ /\.(text|placeholder|accessibilityLabel|title|accessibilityHint)[[:space:]]*=[[:space:]]*"/
  if (waiting) {
    waiting = 0
    if (waitbad && $0 !~ /^[[:space:]]*format:/) bad = 1
  }
  rest = $0
  if (open) {
    open = 0
    arg = $0
    sub(/^[[:space:]]+/, "", arg)
    judge(arg)
  }
  while (match(rest, /(^|[^[:alnum:]_])(Text|Button|Label|navigationTitle|accessibilityLabel|accessibilityValue|accessibilityHint)\(/)) {
    rest = substr(rest, RSTART + RLENGTH)
    if (rest ~ /^[[:space:]]*$/) open = 1
    else judge(rest)
  }
  if (bad) {
    file = FILENAME
    if (index(file, root "/") == 1) file = substr(file, length(root) + 2)
    print file ":" FNR
  }
}' {} + | sort)

if [ -n "$hits" ]
then printf '%s\n' "$hits"
  echo "LOCALIZATION VIOLATION: a plain String reaches the screen. Use a literal, a LocalizedStringResource," \
    "or Text(_, format:). In UIKit, use String(localized:)."
  exit 1
fi
