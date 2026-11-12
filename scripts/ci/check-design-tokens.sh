#!/bin/sh
# Fails when a corner radius is written as a number outside App/Design. The card radius has one name, Corner.card,
# so a number anywhere else would drift from the mockups without any build error.
root=${1:-.}
fail=0
violation() { echo "DESIGN TOKEN VIOLATION: $1" && fail=1; }

radii=$(grep -rEn --include="*.swift" "Radius[[:space:]]*[:(][[:space:]]*[0-9]" "$root/App" | grep -v "^$root/App/Design/")
if [ -n "$radii" ]; then
  echo "$radii"
  violation "writes a corner radius as a number, use Corner.card from App/Design"
fi

glass=$(grep -rEn --include="*.swift" "\.glassProminent" "$root/App" | grep -v "^$root/App/Design/PrimaryButton.swift:")
if [ -n "$glass" ]; then
  echo "$glass"
  violation "writes .glassProminent outside primaryButton(), use .primaryButton() from App/Design"
fi

# The pieces are App/Design and the gallery that shows them. A line's trailing // comment is not code, so it is cut
# before the match.
design="$root/App/Design"
gallery="$root/App/DesignGallery"

# usage: scan <regex> <exempt file> <exempt file> <folder>...
scan() {
  regex=$1 exemptA=$2 exemptB=$3
  shift 3
  find "$@" -name "*.swift" 2> /dev/null | sort | while read -r file; do
    [ "$file" = "$exemptA" ] || [ "$file" = "$exemptB" ] && continue
    sed 's://.*$::' "$file" | grep -En -e "$regex" | sed "s|^|$file:|"
  done
}

numbers=$(scan "(^|[^A-Za-z0-9_.])[1-9]" "$design/Spacing.swift" "$design/Corner.swift" "$design" "$gallery")
if [ -n "$numbers" ]; then
  echo "$numbers"
  violation "writes a number of 1 or more in a piece, name it in Spacing.swift or Corner.swift"
fi

named="red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|white|black|gray|grey"
colours=$(scan "(^|[^A-Za-z0-9_])(Color\\(|UIColor)|#[0-9A-Fa-f]{6}([^0-9A-Fa-f]|$)|\\.($named)([^A-Za-z0-9_]|$)" \
  "$design/ColorTokens.swift" "-" "$design" "$gallery")
if [ -n "$colours" ]; then
  echo "$colours"
  violation "writes a colour in a piece, add a name to ColorTokens.swift"
fi

fonts=$(scan "\\.system\\(size|Font\\.custom|\\.font\\(\\.custom|UIFont" "-" "-" "$design" "$gallery")
if [ -n "$fonts" ]; then
  echo "$fonts"
  violation "writes a fixed or custom font size in a piece, use a text style"
fi

headers=$(scan "\\.textCase\\(|\\.listRowInsets\\(|\\.font\\(" "-" "-" "$gallery")
if [ -n "$headers" ]; then
  echo "$headers"
  violation "styles a header font, case or inset in the gallery, the pieces own that"
fi

# A screen is every file under App/ outside the pieces. It sets no section spacing, row inset, label case, header or
# footer of its own, so a screen cannot drift from the shared look.
# usage: scan_screens <regex>
scan_screens() {
  find "$root/App" -path "$design" -prune -o -name "*.swift" -print 2> /dev/null | sort | while read -r file; do
    sed 's://.*$::' "$file" | grep -En -e "$1" | sed "s|^|$file:|"
  done
}

screen_modifiers="(listSectionSpacing|listRowSpacing|contentMargins|listRowInsets)\\(|\\.textCase\\("
section_closures="\\}[[:space:]]*(header|footer):[[:space:]]*\\{"
section_arguments="(^|[^A-Za-z0-9_])Section\\((.*[^A-Za-z0-9_])?(header|footer):"
sections=$(scan_screens "$screen_modifiers|$section_closures|$section_arguments")
if [ -n "$sections" ]; then
  echo "$sections"
  violation "sets section spacing, inset, case, header or footer in a screen, use App/Design"
fi

# A screen writes no size as a number. A number is its own when no name or decimal point runs into it, so Spacing.x2,
# .title2 and 0.5 pass. A padding or offset call's arguments end at its matching closing parenthesis, at any depth and
# across lines, and the call is reported once, at the line it starts.
# usage: call_number
call_number() {
  find "$root/App" -path "$design" -prune -o -name "*.swift" -print 2> /dev/null | sort | while read -r file; do
    sed 's://.*$::' "$file" | awk -v file="$file" '
      {
        line = $0
        for (i = 1; i <= length(line); i++) {
          if (substr(line, i, 9) == ".padding(" || substr(line, i, 8) == ".offset(") {
            i += (substr(line, i, 2) == ".p") ? 8 : 7
            depth++
            open[++calls] = depth
            start[calls] = NR
            text[calls] = line
            flagged[calls] = 0
            continue
          }
          c = substr(line, i, 1)
          if (c == "(") depth++
          else if (c == ")") {
            depth--
            while (calls > 0 && depth < open[calls]) {
              if (flagged[calls]) print file ":" start[calls] ":" text[calls]
              calls--
            }
          } else if (calls > 0 && c ~ /[1-9]/ && substr(line, i - 1, 1) !~ /[A-Za-z0-9_.]/) {
            for (k = 1; k <= calls; k++) flagged[k] = 1
          }
        }
      }
    '
  done
}
frame_labels="(width|height|minWidth|maxWidth|minHeight|maxHeight)"
size_labels="(^|[^A-Za-z0-9_])($frame_labels|spacing):[[:space:]]*-?[1-9]"
sizes=$(scan_screens "$size_labels" && call_number)
if [ -n "$sizes" ]; then
  echo "$sizes"
  violation "writes a padding, frame, stack spacing or offset as a number in a screen, name it in Spacing.swift"
fi

exit $fail
