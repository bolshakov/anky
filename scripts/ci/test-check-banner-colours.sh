#!/bin/sh
# Proves check-banner-colours.sh fails when the Check In banner's text is hard to read on its soft tint, or when the
# banner or the tokens stop naming that pair, and passes on the app's real files.
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
failures=0

# usage: set_colour <colour set> <light r g b> [<dark r g b>]
# Rewrites a colour set in the current tree. Without dark components the set has no dark entry.
set_colour() {
  file="App/Assets.xcassets/$1.colorset/Contents.json"
  {
    echo '{ "colors" : ['
    echo "  { \"color\" : { \"color-space\" : \"srgb\", \"components\" : {"
    echo "    \"alpha\" : \"1.000\", \"blue\" : \"$4\", \"green\" : \"$3\", \"red\" : \"$2\" } }, \"idiom\" : \"universal\" }"
    if [ -n "$7" ]; then
      echo "  , { \"appearances\" : [ { \"appearance\" : \"luminosity\", \"value\" : \"dark\" } ],"
      echo "    \"color\" : { \"color-space\" : \"srgb\", \"components\" : {"
      echo "    \"alpha\" : \"1.000\", \"blue\" : \"$7\", \"green\" : \"$6\", \"red\" : \"$5\" } }, \"idiom\" : \"universal\" }"
    fi
    echo '], "info" : { "author" : "xcode", "version" : 1 } }'
  } > "$file"
}

# usage: edit <file> <sed expression>
edit() {
  sed "$2" "$1" > "$1.new" && mv "$1.new" "$1"
}

# The light pair is a white tint with a grey text, the dark pair a black tint with a grey text. The "at" grey is the
# nearest to 4.5 that reaches it at eleven digits, and the "below" grey is the next one, which falls just short.
light_at_4_5=0.46531904698
light_below_4_5=0.46531904699
dark_at_4_5=0.45533064311
dark_below_4_5=0.45533064310

# usage: run_in_tree <setup commands>, which leaves the check's output in $out and its exit code in $code.
# The check runs from the repository, whose own files pass, so a check that ignores its root argument passes a tree
# that must fail.
run_in_tree() {
  tree=$(mktemp -d)
  mkdir -p "$tree/App/Assets.xcassets" "$tree/App/Design" "$tree/App/CheckIn"
  cp -R "$repo/App/Assets.xcassets/SoftAccent.colorset" "$repo/App/Assets.xcassets/OnSoftAccent.colorset" \
    "$tree/App/Assets.xcassets/"
  cp "$repo/App/Design/ColorTokens.swift" "$tree/App/Design/"
  cp "$repo/App/CheckIn/CheckInView.swift" "$tree/App/CheckIn/"
  (cd "$tree" && eval "$1")
  out=$(cd "$repo" && "$here/check-banner-colours.sh" "$tree" 2>&1)
  code=$?
  rm -rf "${tree:?}"
}

# usage: verdict -> pass when the check exited 0 with no violation line, fail when it exited 1 with one, else broken
verdict() {
  has_line=$(printf '%s\n' "$out" | grep -c "^BANNER COLOUR VIOLATION: ")
  if [ "$code" = 0 ] && [ "$has_line" = 0 ]; then echo pass
  elif [ "$code" = 1 ] && [ "$has_line" -gt 0 ]; then echo fail
  else echo broken; fi
}

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree>
expect() {
  run_in_tree "$3"
  got=$(verdict)
  if [ "$got" != "$1" ]; then echo "FAIL: $2 (wanted $1, got $got)"; failures=$((failures + 1)); fi
}

# usage: expect_names <description> <setup> <word the violation must contain> <word it must not contain>
expect_names() {
  run_in_tree "$2"
  lines=$(printf '%s\n' "$out" | grep "^BANNER COLOUR VIOLATION: ")
  if [ "$(verdict)" != fail ] || ! printf '%s\n' "$lines" | grep -q "$3" || printf '%s\n' "$lines" | grep -q "$4"; then
    echo "FAIL: $1 (wanted a violation naming $3 and not $4, got: $out)"
    failures=$((failures + 1))
  fi
}

expect pass "the real values" ":"

# Rule: contrast below 4.5 fails, 4.5 and above passes.
expect fail "a light pair with text as pale as the tint" "set_colour OnSoftAccent 0.984 0.898 0.871 1.000 0.710 0.620"
expect fail "a dark pair with text as dark as the tint" "set_colour OnSoftAccent 0.600 0.169 0.059 0.227 0.122 0.086"
light_pair="set_colour SoftAccent 1 1 1 0.227 0.122 0.086"
dark_pair="set_colour SoftAccent 0.984 0.898 0.871 0 0 0"
expect pass "a light pair at 4.5" \
  "$light_pair && set_colour OnSoftAccent $light_at_4_5 $light_at_4_5 $light_at_4_5 1.000 0.710 0.620"
expect fail "a light pair just below 4.5" \
  "$light_pair && set_colour OnSoftAccent $light_below_4_5 $light_below_4_5 $light_below_4_5 1.000 0.710 0.620"
expect pass "a dark pair at 4.5" \
  "$dark_pair && set_colour OnSoftAccent 0.600 0.169 0.059 $dark_at_4_5 $dark_at_4_5 $dark_at_4_5"
expect fail "a dark pair just below 4.5" \
  "$dark_pair && set_colour OnSoftAccent 0.600 0.169 0.059 $dark_below_4_5 $dark_below_4_5 $dark_below_4_5"
expect_names "a failing light pair names light only" \
  "set_colour OnSoftAccent 0.984 0.898 0.871 1.000 0.710 0.620" light dark
expect_names "a failing dark pair names dark only" \
  "set_colour OnSoftAccent 0.600 0.169 0.059 0.227 0.122 0.086" dark light

# Rule: the soft pair is read from both appearances of both colour sets.
expect fail "a tint that matches the light text" "set_colour SoftAccent 0.600 0.169 0.059 0.227 0.122 0.086"
expect fail "a tint that matches the dark text" "set_colour SoftAccent 0.984 0.898 0.871 1.000 0.710 0.620"
expect_names "a tint that matches the light text names light only" \
  "set_colour SoftAccent 0.600 0.169 0.059 0.227 0.122 0.086" light dark
expect_names "a tint that matches the dark text names dark only" \
  "set_colour SoftAccent 0.984 0.898 0.871 1.000 0.710 0.620" dark light

# A colour the check cannot read fails, and never passes.
expect fail "a text colour set without its dark entry" "set_colour OnSoftAccent 0.600 0.169 0.059"
expect fail "a tint colour set without its dark entry" "set_colour SoftAccent 0.984 0.898 0.871"
expect_names "a missing dark entry names dark only" "set_colour OnSoftAccent 0.600 0.169 0.059" dark light
expect fail "a missing text colour set" "rm -r App/Assets.xcassets/OnSoftAccent.colorset"
expect fail "a missing tint colour set" "rm -r App/Assets.xcassets/SoftAccent.colorset"
expect fail "a missing colour set file" "rm App/Assets.xcassets/SoftAccent.colorset/Contents.json"
expect fail "a component in hex" "set_colour OnSoftAccent 0x99 0x2B 0x0F 1.000 0.710 0.620"
expect fail "a component with a hash" "set_colour OnSoftAccent '#992B0F' 0.169 0.059 1.000 0.710 0.620"
expect_names "a hex light component names light only" "set_colour OnSoftAccent 0x99 0.169 0.059 1.000 0.710 0.620" \
  light dark
expect fail "a component above one" "set_colour OnSoftAccent 153 43 15 1.000 0.710 0.620"
expect fail "a component that is empty" "set_colour OnSoftAccent '' 0.169 0.059 1.000 0.710 0.620"
expect fail "a colour set that is not JSON" "echo nonsense > App/Assets.xcassets/SoftAccent.colorset/Contents.json"

# Tokens: Color.soft and Color.onSoft name the two colour sets.
expect fail "Color.soft pointing to another asset" "edit App/Design/ColorTokens.swift 's/Color(\"SoftAccent\")/Color(\"CardBackground\")/'"
expect fail "Color.onSoft pointing to another asset" \
  "edit App/Design/ColorTokens.swift 's/Color(\"OnSoftAccent\")/Color(\"OnAccent\")/'"
expect fail "Color.soft removed" "edit App/Design/ColorTokens.swift 's/static var soft:/static var softer:/'"
expect fail "no tokens file" "rm App/Design/ColorTokens.swift"
expect fail "a token whose right asset is only in a comment" \
  "edit App/Design/ColorTokens.swift 's|Color(\"SoftAccent\")|Color(\"CardBackground\") // Color(\"SoftAccent\")|'"
expect pass "a token with a trailing comment" \
  "edit App/Design/ColorTokens.swift 's|Color(\"SoftAccent\")|Color(\"SoftAccent\") // the tint|'"

# Banner: CheckInView uses the soft tint and its text colour through the tokens.
expect fail "a banner on the card background" \
  "edit App/CheckIn/CheckInView.swift 's/\.background(Color\.soft, in: \.card)/.background(Color(\"CardBackground\"), in: .card)/'"
expect fail "a banner without Color.onSoft" "edit App/CheckIn/CheckInView.swift 's/\.foregroundStyle(Color\.onSoft)/.foregroundStyle(Color.ink)/'"
expect fail "a banner that names the asset instead of the token" \
  "edit App/CheckIn/CheckInView.swift 's/\.background(Color\.soft, in: \.card)/.background(Color(\"SoftAccent\"), in: .card)/'"
expect fail "a banner whose tint is only in a comment" \
  "edit App/CheckIn/CheckInView.swift 's|\.background(Color\.soft, in: \.card)|.background(Color.card, in: .card) // .background(Color.soft, in: .card)|'"
expect fail "a banner whose text colour is on a commented line" \
  "edit App/CheckIn/CheckInView.swift 's|\.foregroundStyle(Color\.onSoft)|// .foregroundStyle(Color.onSoft)|'"
expect fail "no banner file" "rm App/CheckIn/CheckInView.swift"
expect_names "a banner on the card background names the Check In banner" \
  "edit App/CheckIn/CheckInView.swift 's/\.background(Color\.soft, in: \.card)/.background(Color.card, in: .card)/'" \
  "Check In banner" "nothing-at-all-in-the-message"
expect pass "a banner modifier with a trailing comment" \
  "edit App/CheckIn/CheckInView.swift 's|\.background(Color\.soft, in: \.card)|.background(Color.soft, in: .card) // the tint|'"

# The root argument is the tree that is read. With none, the current folder is.
bad=$(mktemp -d)
mkdir -p "$bad/App/Assets.xcassets/OnSoftAccent.colorset" "$bad/App/Design" "$bad/App/CheckIn"
cp -R "$repo/App/Assets.xcassets/SoftAccent.colorset" "$bad/App/Assets.xcassets/"
cp "$repo/App/Design/ColorTokens.swift" "$bad/App/Design/"
cp "$repo/App/CheckIn/CheckInView.swift" "$bad/App/CheckIn/"
(cd "$bad" && set_colour OnSoftAccent 0.984 0.898 0.871 0.227 0.122 0.086)

if (cd "$repo" && "$here/check-banner-colours.sh" "$bad" > /dev/null 2>&1); then
  echo "FAIL: a root argument to a bad tree, run from a good one (wanted fail, got pass)"
  failures=$((failures + 1))
fi
if (cd "$bad" && "$here/check-banner-colours.sh" "$repo" > /dev/null 2>&1); then :; else
  echo "FAIL: a root argument to a good tree, run from a bad one (wanted pass, got fail)"
  failures=$((failures + 1))
fi
if (cd "$bad" && "$here/check-banner-colours.sh" > /dev/null 2>&1); then
  echo "FAIL: no root argument, run in a bad tree (wanted fail, got pass)"
  failures=$((failures + 1))
fi
if (cd "$repo" && "$here/check-banner-colours.sh" > /dev/null 2>&1); then :; else
  echo "FAIL: no root argument, run in a good tree (wanted pass, got fail)"
  failures=$((failures + 1))
fi
rm -rf "${bad:?}"

[ "$failures" = 0 ] && echo "check-banner-colours tests: all passed"
exit "$failures"
