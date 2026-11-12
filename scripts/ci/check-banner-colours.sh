#!/bin/sh
# Fails when the Check In banner's text is not readable on its soft tint, in light or in dark, or when the banner or
# the colour tokens stop naming that pair, so a restyle or a colour edit cannot make the banner unreadable unnoticed.
root=${1:-.}
fail=0
violation() { echo "BANNER COLOUR VIOLATION: $1" && fail=1; }

minimum_ratio=4.5
assets="$root/App/Assets.xcassets"

# usage: entries <colour set file>
# Prints one line per colour in the set, "<light|dark|other> <red> <green> <blue>", with "-" for a component it cannot
# find. A colour with no appearances is light, and the one for the dark luminosity is dark.
entries() {
  tr '\n' ' ' < "$1" | awk '
    function component(entry, name,   found) {
      if (!match(entry, "\"" name "\"[ ]*:[ ]*\"[^\"]*\"")) return "-"
      found = substr(entry, RSTART, RLENGTH)
      sub("^\"" name "\"[ ]*:[ ]*\"", "", found)
      sub("\"$", "", found)
      gsub(/[ \t]/, "_", found)
      return found == "" ? "-" : found
    }
    function emit(entry,   kind) {
      kind = "light"
      if (entry ~ /"appearances"/) {
        kind = (entry ~ /"appearance"[ ]*:[ ]*"luminosity"/ && entry ~ /"value"[ ]*:[ ]*"dark"/) ? "dark" : "other"
      }
      print kind, component(entry, "red"), component(entry, "green"), component(entry, "blue")
    }
    {
      depth = 0
      entry = ""
      for (i = 1; i <= length($0); i++) {
        ch = substr($0, i, 1)
        if (ch == "{" || ch == "[") depth++
        if (depth >= 3) entry = entry ch
        if (ch == "}" || ch == "]") {
          if (depth == 3) { emit(entry); entry = "" }
          depth--
        }
      }
    }'
}

# usage: rgb <colour set> <light|dark>
# Prints the three components of the set for that appearance. When they cannot be read it prints the reason and fails.
rgb() {
  file="$assets/$1.colorset/Contents.json"
  [ -f "$file" ] || { echo "$1 has no colour set at App/Assets.xcassets/$1.colorset"; return 1; }
  found=$(entries "$file" | awk -v want="$2" '$1 == want { print $2, $3, $4; exit }')
  [ -n "$found" ] || { echo "$1 has no $2 entry"; return 1; }
  for component in $found; do
    if ! printf '%s\n' "$component" | grep -Eq '^(0(\.[0-9]+)?|1(\.0+)?)$'; then
      echo "$1 has a $2 component \"$component\" that is not a decimal from 0 to 1"
      return 1
    fi
  done
  echo "$found"
}

# usage: ratio <text r g b> <tint r g b>
# Prints "ok <ratio>" or "low <ratio>", the WCAG 2.x contrast ratio of the text on the tint against the minimum.
ratio() {
  echo "$@" | awk -v minimum="$minimum_ratio" '
    function linear(c) { return c <= 0.03928 ? c / 12.92 : exp(2.4 * log((c + 0.055) / 1.055)) }
    function luminance(r, g, b) { return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b) }
    {
      text = luminance($1, $2, $3)
      tint = luminance($4, $5, $6)
      high = text > tint ? text : tint
      low = text > tint ? tint : text
      value = (high + 0.05) / (low + 0.05)
      printf "%s %.2f\n", (value >= minimum ? "ok" : "low"), value
    }'
}

# usage: check_contrast <light|dark>
check_contrast() {
  appearance=$1
  tint_ok=1
  if ! tint=$(rgb SoftAccent "$appearance"); then violation "$tint"; tint_ok=0; fi
  if ! text=$(rgb OnSoftAccent "$appearance"); then violation "$text"; return; fi
  [ "$tint_ok" = 1 ] || return
  result=$(ratio "$text" "$tint")
  case "$result" in
    "ok "*) ;;
    "low "*) violation "OnSoftAccent on SoftAccent has a $appearance contrast of ${result#* }, below $minimum_ratio" ;;
    *) violation "the $appearance contrast of OnSoftAccent on SoftAccent could not be computed" ;;
  esac
}

check_contrast light
check_contrast dark

# usage: source_of <swift file>
# Prints the file as one line with each trailing // comment cut, so a match can span lines and a comment is not code.
source_of() {
  sed 's://.*$::' "$1" 2> /dev/null | tr '\n' ' '
}

tokens=$(source_of "$root/App/Design/ColorTokens.swift")
space="[[:space:]]*"

# usage: check_token <token> <asset>
check_token() {
  declaration="static${space}var[[:space:]]+$1${space}:${space}Color${space}\\{${space}(return[[:space:]]+)?"
  if ! printf '%s\n' "$tokens" | grep -Eq "${declaration}Color\\(\"$2\"\\)${space}\\}"; then
    violation "Color.$1 must be Color(\"$2\") in App/Design/ColorTokens.swift"
  fi
}

check_token soft SoftAccent
check_token onSoft OnSoftAccent

banner=$(source_of "$root/App/CheckIn/CheckInView.swift")

if ! printf '%s\n' "$banner" | grep -Eq "\\.foregroundStyle\\(${space}Color\\.onSoft${space}\\)"; then
  violation "the Check In banner must set Color.onSoft as its foregroundStyle in App/CheckIn/CheckInView.swift"
fi
if ! printf '%s\n' "$banner" | grep -Eq "\\.background\\(${space}Color\\.soft${space}[,)]"; then
  violation "the Check In banner must set Color.soft as its background in App/CheckIn/CheckInView.swift"
fi

exit $fail
