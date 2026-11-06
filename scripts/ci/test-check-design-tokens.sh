#!/bin/sh
# Proves check-design-tokens.sh fails on a numeric corner radius under App/ and passes everywhere the rule allows.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree>
expect() {
  want=$1 desc=$2 setup=$3
  tree=$(mktemp -d)
  mkdir -p "$tree/App"
  printf 'import SwiftUI\n' > "$tree/App/AnkyApp.swift"
  (cd "$tree" && eval "$setup")
  if "$here/check-design-tokens.sh" "$tree" > /dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then echo "FAIL: $desc (wanted $want, got $got)"; failures=$((failures + 1)); fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" ":"
expect fail "a rounded rectangle with a number" "echo 'let s = RoundedRectangle(cornerRadius: 16)' > App/Card.swift"
expect fail "a rect shape with a number" "echo 'let s = Color.red.clipShape(.rect(cornerRadius: 12))' > App/Card.swift"
expect fail "the cornerRadius modifier with a number" "echo 'let v = Text(\"a\").cornerRadius(8)' > App/Badge.swift"
expect fail "an uneven corner with a number" "echo 'let s = UnevenRoundedRectangle(topLeadingRadius: 16)' > App/Tab.swift"
expect fail "a number in a nested folder" "mkdir -p App/Today && echo 'let s = RoundedRectangle(cornerRadius: 16)' > App/Today/Row.swift"
expect pass "a capsule" "echo 'let s = Capsule()' > App/Pill.swift"
expect pass "the shared card shape" "echo 'let v = Text(\"a\").background(Color(\"CardBackground\"), in: .card)' > App/Card.swift"
expect pass "the named card radius outside App/Design" "echo 'let s = RoundedRectangle(cornerRadius: Corner.card)' > App/Card.swift"
expect pass "a number inside App/Design" "mkdir -p App/Design && echo 'let s = RoundedRectangle(cornerRadius: 22)' > App/Design/Corner.swift"
expect pass "a number outside App" "mkdir -p Sources/AnkyDomain && echo 'let s = RoundedRectangle(cornerRadius: 16)' > Sources/AnkyDomain/Shape.swift"
expect fail "a raw prominent glass button in a screen" "echo 'let b = Button(\"a\") {}.buttonStyle(.glassProminent)' > App/TodayView.swift"
expect fail "a raw prominent glass button in a nested folder" "mkdir -p App/Today && echo 'let b = Button(\"a\") {}.buttonStyle(.glassProminent)' > App/Today/Row.swift"
expect fail "a raw prominent glass button beside the one place" "mkdir -p App/Design && echo 'let b = Button(\"a\") {}.buttonStyle(.glassProminent)' > App/Design/Corner.swift"
expect pass "the one place for a prominent glass button" "mkdir -p App/Design && echo 'let b = Button(\"a\") {}.buttonStyle(.glassProminent)' > App/Design/PrimaryButton.swift"
expect pass "a glass button that is not prominent" "echo 'let b = Button(\"a\") {}.buttonStyle(.glass)' > App/TodayView.swift"
expect pass "a bordered prominent button" "echo 'let b = Button(\"a\") {}.buttonStyle(.borderedProminent)' > App/TodayView.swift"
expect pass "a prominent glass button outside App" "mkdir -p Sources/AnkyDomain && echo 'let b = Button(\"a\") {}.buttonStyle(.glassProminent)' > Sources/AnkyDomain/Shape.swift"

# Rule: a number of 1 or more in the pieces, outside Spacing.swift and Corner.swift.
expect fail "a number in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").padding(16)' > App/Design/Row.swift"
expect fail "a decimal above one in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").opacity(1.5)' > App/Design/Row.swift"
expect fail "a number in the gallery" "mkdir -p App/DesignGallery && echo 'let v = Text(\"a\").frame(height: 52)' > App/DesignGallery/Demo.swift"
expect pass "a number in Spacing.swift" "mkdir -p App/Design && echo 'let rowHeight: CGFloat = 52' > App/Design/Spacing.swift"
expect pass "a number in Corner.swift" "mkdir -p App/Design && echo 'let card: CGFloat = 22' > App/Design/Corner.swift"
expect pass "zero and a fraction in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").opacity(0.5).offset(x: 0)' > App/Design/Row.swift"
expect pass "a digit inside a name in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").foregroundStyle(Color.ink2).font(.title2)' > App/Design/Row.swift"
expect pass "a number in a comment in a piece" "mkdir -p App/Design && echo 'let v = 0 // the row is 52 pt' > App/Design/Row.swift"
expect pass "a number in a screen outside the pieces" "mkdir -p App/Today && echo 'let v = Text(\"a\").padding(16)' > App/Today/Row.swift"

# Rule: a colour written outside ColorTokens.swift.
expect fail "Color( in a piece" "mkdir -p App/Design && echo 'let c = Color(\"CardBackground\")' > App/Design/Row.swift"
expect fail "UIColor in a piece" "mkdir -p App/Design && echo 'let c = UIColor.label' > App/Design/Row.swift"
expect fail "a hex colour in a piece" "mkdir -p App/Design && echo 'let c = \"#FF8800\"' > App/Design/Row.swift"
expect fail "a named system colour in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").foregroundStyle(.orange)' > App/Design/Row.swift"
expect fail "a named system colour with its type in the gallery" "mkdir -p App/DesignGallery && echo 'let c = Color.white' > App/DesignGallery/Demo.swift"
expect pass "Color( in ColorTokens.swift" "mkdir -p App/Design && echo 'let c = Color(\"CardBackground\")' > App/Design/ColorTokens.swift"
expect pass "UIColor in ColorTokens.swift" "mkdir -p App/Design && echo 'let c = UIColor.label' > App/Design/ColorTokens.swift"
expect pass "a token name in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").foregroundStyle(Color.ink)' > App/Design/Row.swift"
expect pass "a clear row background in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").listRowBackground(Color.clear)' > App/Design/Row.swift"
expect pass "a member that starts like a colour in a piece" "mkdir -p App/Design && echo 'let v = items.reduce(0, +).redacted' > App/Design/Row.swift"
expect pass "a colour in a screen outside the pieces" "mkdir -p App/Today && echo 'let v = Text(\"a\").foregroundStyle(.orange)' > App/Today/Row.swift"

# Rule: a fixed or custom font size.
expect fail "a system font size in a piece" "mkdir -p App/Design && echo 'let f = Font.system(size: 17)' > App/Design/Row.swift"
expect fail "a shorthand system font size in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").font(.system(size: .zero))' > App/Design/Row.swift"
expect fail "Font.custom in a piece" "mkdir -p App/Design && echo 'let f = Font.custom(\"Name\", size: .zero)' > App/Design/Row.swift"
expect fail "a custom font in a modifier in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").font(.custom(\"Name\", size: .zero))' > App/Design/Row.swift"
expect fail "UIFont in the gallery" "mkdir -p App/DesignGallery && echo 'let f = UIFont.preferredFont(forTextStyle: .body)' > App/DesignGallery/Demo.swift"
expect pass "a text style font in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").font(.body)' > App/Design/Row.swift"
expect pass "a system font size in a screen outside the pieces" "mkdir -p App/Today && echo 'let f = Font.system(size: .zero)' > App/Today/Row.swift"

# Rule: the gallery styles no header of its own.
expect fail "textCase in the gallery" "mkdir -p App/DesignGallery && echo 'let v = Text(\"a\").textCase(nil)' > App/DesignGallery/Demo.swift"
expect fail "listRowInsets in the gallery" "mkdir -p App/DesignGallery && echo 'let v = Text(\"a\").listRowInsets(EdgeInsets())' > App/DesignGallery/Demo.swift"
expect fail "a font in the gallery" "mkdir -p App/DesignGallery && echo 'let v = Text(\"a\").font(.body)' > App/DesignGallery/Demo.swift"
expect pass "textCase in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").textCase(nil)' > App/Design/Row.swift"
expect pass "listRowInsets in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").listRowInsets(EdgeInsets())' > App/Design/Row.swift"
expect pass "a font in a piece" "mkdir -p App/Design && echo 'let v = Text(\"a\").font(.body)' > App/Design/Row.swift"
expect pass "a clean gallery" "mkdir -p App/DesignGallery && echo 'let v = Text(verbatim: \"a\").nonCardBlock()' > App/DesignGallery/Demo.swift"

[ "$failures" = 0 ] && echo "check-design-tokens tests: all passed"
exit "$failures"
