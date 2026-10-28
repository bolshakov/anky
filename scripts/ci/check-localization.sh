#!/bin/sh
# Fails when text on screen skips the string catalog, so each new string needs a catalog entry.
root=${1:-.}
app="$root/App"

# The grep cannot see a type, so a bare name passes only when App/ declares it as a resource or a Text.
resources=$(grep -rhoE --include="*.swift" \
  '[[:alnum:]_]+(\([^)]*\))?[[:space:]]*(:|->)[[:space:]]*(LocalizedStringResource|LocalizedStringKey|Text)([^[:alnum:](]|$)' "$app" |
  sed -E 's/^([[:alnum:]_]+).*/\1/' | tr '\n' ' ')
# A name declared as a String anywhere is not trusted, because the grep cannot tell which declaration a use means.
strings=$(grep -rhoE --include="*.swift" \
  '[[:alnum:]_]+(\([^)]*\))?[[:space:]]*(:|->)[[:space:]]*String([^[:alnum:](]|$)' "$app" |
  sed -E 's/^([[:alnum:]_]+).*/\1/' | tr '\n' ' ')

hits=$(find "$app" -name '*.swift' -exec awk -v root="$root" -v resources="$resources" -v strings="$strings" '
# Only the first argument counts, so a format: in a later call on the same line does not.
function formatted(rest, i, c, depth) {
  depth = 0
  for (i = 1; i <= length(rest); i++) {
    c = substr(rest, i, 1)
    if (c == "(") depth++
    else if (c == ")") {
      if (depth == 0) return 0
      depth--
    } else if (c == "," && depth == 0) return substr(rest, i) ~ /^, format:/
  }
  return 0
}
function allowed(rest, arg, name) {
  if (rest ~ /^"([^"\\]|\\.)*"([,)]|[[:space:]]*$)/ || rest ~ /^(Text\(|LocalizedString)/) return 1
  if (rest ~ /^[[:alnum:]_]+:/ && rest !~ /^verbatim:/) return 1
  if (formatted(rest)) return 1
  arg = rest
  sub(/[,)].*/, "", arg)
  name = arg
  sub(/\(.*/, "", name)
  sub(/.*\./, "", name)
  return name != "" && index(" " resources " ", " " name " ") > 0 && index(" " strings " ", " " name " ") == 0
}
function judge(rest) {
  if (rest ~ /,[[:space:]]*$/) {
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
