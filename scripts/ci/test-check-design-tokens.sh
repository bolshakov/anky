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

# Rule: a screen writes no padding, frame, stack spacing or offset as a number. A case is a line of a screen, written
# into App/Today/Row.swift unless it says otherwise.
# usage: expect_screen <pass|fail> <description> <line>
expect_screen() {
  expect "$1" "$2" "mkdir -p App/Today && cat > App/Today/Row.swift <<'EOF'
$3
EOF"
}

expect_screen fail "a padding with a number" 'let v = Text("a").padding(16)'
expect_screen fail "a padding with an edge and a number" 'let v = Text("a").padding(.horizontal, 32)'
expect_screen fail "a padding with a negative number" 'let v = Text("a").padding(.leading, -16)'
expect_screen fail "a padding with a number in a conditional" 'let v = Text("a").padding(.top, flag ? 48 : 64)'
expect_screen fail "a padding with a number in a call" 'let v = Text("a").padding(.top, max(4, inset))'
expect_screen fail "a padding with a number after a name in a call" 'let v = Text("a").padding(.top, max(inset, 4))'
expect_screen fail "a padding with a number in an insets call" 'let v = Text("a").padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))'
expect_screen fail "an offset with a number after a name in a call" 'let v = Text("a").offset(x: max(a, 4))'
expect_screen fail "a padding with a number after a named value" 'let v = Text("a").padding(Spacing.tightGap + 4)'
expect_screen fail "a frame width with a number" 'let v = Text("a").frame(width: 120)'
expect_screen fail "a frame height with a number" 'let v = Text("a").frame(height: 52)'
expect_screen fail "a frame minWidth with a number" 'let v = Text("a").frame(minWidth: 44)'
expect_screen fail "a frame maxWidth with a number" 'let v = Text("a").frame(maxWidth: 300)'
expect_screen fail "a frame minHeight with a number" 'let v = Text("a").frame(minHeight: 44)'
expect_screen fail "a frame maxHeight with a number" 'let v = Text("a").frame(maxHeight: 200)'
expect_screen fail "a frame width with a negative number" 'let v = Text("a").frame(width: -8)'
expect_screen fail "a frame label on its own line" '    width: 120,'
expect_screen fail "a VStack spacing with a number" 'let v = VStack(spacing: 12) { }'
expect_screen fail "an HStack spacing with a number" 'let v = HStack(alignment: .top, spacing: 8) { }'
expect_screen fail "a LazyVStack spacing with a number" 'let v = LazyVStack(spacing: 4) { }'
expect_screen fail "a layout spacing with a number" 'let v = HStackLayout(spacing: 4)'
expect_screen fail "an offset x with a number" 'let v = Text("a").offset(x: 4)'
expect_screen fail "an offset y with a negative number" 'let v = Text("a").offset(y: -6)'
expect fail "a number in a screen beside the pieces" "mkdir -p App/Today App/Design && echo 'let v = 0' > App/Design/Row.swift && echo 'let v = Text(\"a\").padding(16)' > App/Today/Row.swift"
expect_screen pass "a padding of zero" 'let v = Text("a").padding(0)'
expect_screen pass "a padding with a named value" 'let v = Text("a").padding(.horizontal, Spacing.screenMargin)'
expect_screen pass "a padding with a digit inside a name" 'let v = Text("a").padding(.top, Spacing.x2)'
expect_screen pass "a padding with a digit inside a name in a call" 'let v = Text("a").padding(.top, max(inset, Spacing.x2))'
expect_screen pass "a padding followed by a call with a number" 'let v = Text("a").padding(Spacing.tightGap).lineLimit(2)'
expect_screen pass "a frame that fills the width" 'let v = Text("a").frame(maxWidth: .infinity)'
expect_screen pass "a frame height with a named value" 'let v = Text("a").frame(height: Spacing.rowHeight)'
expect_screen pass "a frame height of zero" 'let v = Text("a").frame(height: 0)'
expect_screen pass "a line width in a stroke" 'let v = Circle().stroke(lineWidth: 2)'
expect_screen pass "a stack spacing of zero" 'let v = VStack(spacing: 0) { }'
expect_screen pass "a stack spacing with a named value" 'let v = VStack(spacing: Spacing.labelGap) { }'
expect_screen pass "a property named spacing" 'static let spacing: CGFloat = Spacing.labelGap'
expect_screen pass "an offset of zero" 'let v = Text("a").offset(x: 0)'
expect_screen pass "an offset with a named value" 'let v = Text("a").offset(y: Spacing.tightGap)'
expect_screen pass "a text style with a digit inside" 'let v = Text("a").font(.title2)'
expect_screen pass "a number in a trailing comment" 'let v = 0 // the gap is 12 pt'
expect_screen pass "a padding in a trailing comment" 'let v = 0 // .padding(16) and .frame(width: 120)'
expect pass "a padding with a number in the piece that names sizes" "mkdir -p App/Design && echo 'let v = Text(\"a\").padding(16)' > App/Design/Spacing.swift"

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

# Rule: a screen sets no section spacing, row inset, label case, header or footer of its own.
expect fail "listSectionSpacing in a screen" "mkdir -p App/Today && echo 'let v = List {}.listSectionSpacing(.custom(10))' > App/Today/Row.swift"
expect fail "listRowSpacing in a screen" "mkdir -p App/Today && echo 'let v = List {}.listRowSpacing(4)' > App/Today/Row.swift"
expect fail "contentMargins in a screen" "mkdir -p App/Today && echo 'let v = List {}.contentMargins(.top, 4)' > App/Today/Row.swift"
expect fail "listRowInsets in a screen" "mkdir -p App/Today && echo 'let v = Text(\"a\").listRowInsets(EdgeInsets())' > App/Today/Row.swift"
expect fail "textCase in a screen" "mkdir -p App/Today && echo 'let v = Text(\"a\").textCase(nil)' > App/Today/Row.swift"
expect fail "a trailing header closure in a screen" "mkdir -p App/Today && echo '} header: {' > App/Today/Row.swift"
expect fail "a trailing footer closure in a screen" "mkdir -p App/Today && echo '} footer: {' > App/Today/Row.swift"
expect fail "a header closure after a one-line section" "mkdir -p App/Today && echo 'Section { Text(\"a\") } header: { Text(\"h\") }' > App/Today/Row.swift"
expect fail "a header argument on a Section" "mkdir -p App/Today && echo 'Section(header: Text(\"h\")) { Text(\"a\") }' > App/Today/Row.swift"
expect fail "a footer argument on a Section" "mkdir -p App/Today && echo 'Section(footer: Text(\"f\")) { Text(\"a\") }' > App/Today/Row.swift"
expect fail "a header argument after a title on a Section" "mkdir -p App/Today && echo 'Section(\"t\", header: Text(\"h\")) {' > App/Today/Row.swift"
expect fail "a section modifier in the gallery" "mkdir -p App/DesignGallery && echo 'let v = List {}.listRowSpacing(.zero)' > App/DesignGallery/Demo.swift"
expect fail "a section modifier in a screen beside the pieces" "mkdir -p App/Today App/Design && echo 'let v = 0' > App/Design/Row.swift && echo 'let v = List {}.listRowSpacing(4)' > App/Today/Row.swift"
expect pass "listSectionSpacing in a piece" "mkdir -p App/Design && echo 'let v = List {}.listSectionSpacing(.custom(.zero))' > App/Design/Row.swift"
expect pass "listRowSpacing in a piece" "mkdir -p App/Design && echo 'let v = List {}.listRowSpacing(.zero)' > App/Design/Row.swift"
expect pass "contentMargins in a piece" "mkdir -p App/Design && echo 'let v = List {}.contentMargins(.top, .zero)' > App/Design/Row.swift"
expect pass "a trailing header closure in a piece" "mkdir -p App/Design && echo '} header: {' > App/Design/Row.swift"
expect pass "a trailing footer closure in a piece" "mkdir -p App/Design && echo '} footer: {' > App/Design/Row.swift"
expect pass "a header argument on a Section in a piece" "mkdir -p App/Design && echo 'Section(header: Text(\"h\")) { Text(\"a\") }' > App/Design/Row.swift"
expect pass "a footer argument on a Section in a piece" "mkdir -p App/Design && echo 'Section(footer: Text(\"f\")) { Text(\"a\") }' > App/Design/Row.swift"
expect pass "a screen modifier in a trailing comment" "mkdir -p App/Today && echo 'let v = 0 // .listRowInsets(EdgeInsets()) and .textCase(nil)' > App/Today/Row.swift"
expect pass "a header closure in a trailing comment" "mkdir -p App/Today && echo 'let v = 0 // } header: {' > App/Today/Row.swift"
expect pass "a footer argument in a trailing comment" "mkdir -p App/Today && echo 'Section { Text(\"a\") } // footer: Text(\"f\")' > App/Today/Row.swift"
expect pass "a section without a header or footer" "mkdir -p App/Today && echo 'Section { Text(\"a\") }' > App/Today/Row.swift"
expect pass "a property named footer" "mkdir -p App/Today && echo 'var footer: LocalizedStringKey?' > App/Today/Row.swift"
expect pass "a footer argument on a screen view" "mkdir -p App/Today && echo 'SystemSeveritySection(title: \"t\", footer: footnote)' > App/Today/Row.swift"
expect pass "a footer argument on a card section" "mkdir -p App/Today && echo 'CardSection(Text(\"t\"), footnote: footer.map { Text(\$0) }, id: \"a\") {' > App/Today/Row.swift"
expect pass "a header argument on a view named like a section" "mkdir -p App/Today && echo 'DateSection(header: Text(\"h\"))' > App/Today/Row.swift"
expect pass "a similar name that is no modifier" "mkdir -p App/Today && echo 'let contentMarginsTotal = 0' > App/Today/Row.swift"

[ "$failures" = 0 ] && echo "check-design-tokens tests: all passed"
exit "$failures"
