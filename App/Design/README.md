# The design catalog

Read this before you build or change anything a person sees. Each shared piece under `App/Design` has one line below:
when to use it, and what not to build instead. Find the piece by name here, and build a new one only when no line fits.
A line states why, so open the Swift file for what the piece takes.

This file changes in the same pull request as the piece it names. `scripts/ci/check-ui-catalog.sh` fails when a piece
has no entry line, or an entry line names no piece. One entry line covers every piece that shares its name.

## Rules

- A screen never sets the title display mode. Today's header moved by `.inlineLarge` and the change was rolled back, so
  a screen keeps the system's default for its navigation bar.
- A footnote goes in the footer of `FootnotedSection` and never in an empty trailing section. A trailing section built
  only to hold the footnote sat about 42 pt from its card, away from the group it explains.
- A screen takes no raw asset colour, no `Color("...")` and no UIKit colour. It uses the colour tokens below, which are
  the only place an asset is named.

## Sections

- `CardSection`: the default section of a card screen, with an optional label above and a left-aligned footnote below. Do not build a `Section` with its own card background, header style and footer inset.
- `FootnotedSection`: a section of a grouped list that keeps the system footer inset and tint for its footnote. Do not put the footnote in an extra empty section after it.
- `FooterBlockSection`: a card section whose footer is a centred block of any views that scrolls with the list, such as the About block. Do not hand-build a footer for it, and use `CardSection` when the footer is only left-aligned text.
- `SectionLabel`: the header style of a section label. `CardSection` and `FootnotedSection` apply it already, so use it by hand only on a `Section` you build yourself, and never set a header's case and insets yourself.

## Rows

- `IconRow`: the one row that shows an entry, a dose or a reading, with a tile, two lines and a trailing item. Do not build a second row with a leading symbol, and label it in the wrapper, since it sets no accessibility label.
- `IconTile`: the small symbol tile that starts an `IconRow`, decoration that VoiceOver skips. Do not draw a tinted square behind a symbol yourself.
- `ValueRow`: a title with a value on the trailing side, with a chevron when it has an action. Do not build a `LabeledContent` row, and give it no action when it is the label of a `NavigationLink`, which draws its own chevron.
- `TwoLineRow`: a title over a subtitle with an optional value, with a chevron when it has an action. Use `ValueRow` when one line is enough, and do not stack two texts in a row yourself.
- `TintRow`: one row in a list where a single item is chosen, with the chosen one bold and ticked. Do not draw your own checkmark row or a tick in another colour.
- `SwitchRow`: a row with a toggle. Do not put a bare `Toggle` in a card, since it would differ in height and tint.
- `MenuRow`: a row whose value is picked from a menu. Do not put a bare `Picker` in a card.
- `RowChevron`: the chevron at the end of a tappable row you lay out yourself. `ValueRow` and `TwoLineRow` draw it already, and a `NavigationLink` has its own, so do not draw a chevron from a symbol name.

## Modifiers for rows and lists

- `rowHeight`: the height of a row in a card, which grows with Dynamic Type and never drops below the row minimum. One line covers the `View` modifier you put on a row and the `Spacing` token that is its default. Do not set a minimum height or a row's vertical inset yourself.
- `fillsCardRow`: for a row whose content brings its own vertical padding, so the card adds none. `rowHeight` applies it already, so do not set the list row's vertical inset by hand.
- `cardCaption`: for a caption that sits inside a card block and lines up with its left edge in its own case. Do not set the text case, frame and leading inset on a caption yourself.
- `deleteSwipe`: the trailing swipe that deletes a row. Do not build your own swipe action with a delete button.
- `minimumTapTarget`: gives a small control the minimum hit area, and VoiceOver reports that box and not the control. Do not add a bare frame of the tap-target size, which leaves the touch and accessibility shape unchanged.
- `nonCardBlock`: a row that sits on the page and not in a card, with a clear background, no insets and no separator. Do not clear those three on a row one by one.

## Modifiers for screens and buttons

- `screenSpacing`: the margins, first-block offset, section gap and page background of a card list screen. Do not set content margins, section spacing or the scroll background on a screen yourself.
- `readingScreenSpacing`: the margins of a screen of running text that is not a card list, with room at the bottom. Do not reuse `screenSpacing` for it, since that one also hides the scroll background.
- `lastBlockClearance`: room under the last block of a list that has no bottom button. Do not add a bottom padding.
- `emptyBlockGap`: the wide gap between sections around an empty-state block in a list, and the same gap as top padding for an empty state outside a list. One line covers the `View` modifier and the `Spacing` token. Do not write a gap.
- `blockGapBetweenSections`: the standard gap between sections for a list that is not set up by `screenSpacing`. Do not call `listSectionSpacing` with a number.
- `todayTopMargin`: pulls Today's list up toward its large title and follows the title as Dynamic Type grows it. Only Today uses it. Do not copy it to another screen, and do not nudge a list's top by hand.
- `primaryButton`: the prominent style for a button, with its label colour set to match. Do not apply the glass prominent style yourself.
- `bottomPrimaryButton`: the screen's one main action pinned above the bottom edge, where `isEnabled` dims only the button. Do not add your own bottom inset with a button, and do not use `.disabled` on the screen for it.

## Tips

- `TipCard`: the one look of every tip, with an icon, title, message and dismiss action. Do not build a tip from `Spacing` tokens, and do not set its colour, font or padding on a screen.
- `TipCardStyle`: the `TipViewStyle` that draws a TipKit tip with `TipCard` and invalidates the tip on dismiss. Pass it to `.tipViewStyle` and do not write a second style.

## Spacing tokens

Every spacing and size under `App/` is a `Spacing` token, so a screen writes no number for one. Add a token to
`Spacing.swift` when none fits.

- `Spacing`: the home of every spacing and size. Do not write a point value in a screen or in a piece.
- `screenMargin`: the side margin of a screen. `screenSpacing` applies it to lists, so use it for content you place outside a list, such as an inset bar. Do not write a horizontal padding number.
- `firstBlockTop`: the gap between the navigation bar and the first block, which `screenSpacing` applies. Use it for the same gap in a stack that is not a list.
- `titleToDatePull`: only for `todayTopMargin`, which sets how far Today's list is pulled up. Do not use it to align another header.
- `titleToDatePullPerTitlePoint`: only for `todayTopMargin`, which shrinks the pull as the title grows. Do not use it to align another header.
- `largeTitleSize`: only for `todayTopMargin`, as the title size the pull is measured from. Do not use it to size text.
- `blockGap`: the gap between the blocks of a screen, applied by `screenSpacing`. Do not set a different section gap.
- `emptyBlockGap`: covered by the `emptyBlockGap` line under Modifiers for screens and buttons.
- `labelGap`: the gap under a section label, applied by `SectionLabel`. Do not pad a label yourself.
- `readingBlockGap`: the gap between blocks of running text on a reading screen. Do not use it in a card list.
- `listItemGap`: the gap between the items of a list inside running text. Do not use it between card rows.
- `footnoteGap`: the gap between a card and its footnote, applied by `CardSection`. Do not pad a footnote yourself.
- `inlineGap`: the gap between related items in one block, such as a caption above its control. Do not write one.
- `tightGap`: the smallest gap between items that belong together, such as a symbol and its short label. Do not write a small number.
- `textLinesGap`: the gap between the two text lines of a row. Do not use it between blocks.
- `rowContentGap`: the gap between a row's tile or symbol and its text. Do not use it between rows.
- `cardContentGap`: the gap between items stacked inside one card block, such as a question and its answer control. Do not write one.
- `cardInset`: the side inset for content you draw inside a card by hand, so it lines up with the rows. Do not write a padding number.
- `pairGap`: the gap between two blocks that sit side by side and stack at accessibility sizes, as on Today. Do not write one.
- `moreRowGap`: the gap between the parts of the more-places row. Do not reuse it for another row.
- `chipInnerGap`: the gap between the symbol and the text inside a chip. Do not write one.
- `chevronSlotWidth`: the width of a chevron slot in the more-places row. Other rows take `RowChevron` instead.
- `chevronSlotHeight`: the height of a chevron slot in the more-places row. Other rows take `RowChevron` instead.
- `tapTarget`: the minimum hit area of a control. `minimumTapTarget` applies it, so use the modifier before the token.
- `weekdayRowHeight`: only for the weekday picker row of the schedule. Do not use it for another row, which takes `rowHeight`.
- `weekdayRowPadding`: only for the weekday picker row of the schedule. Do not use it as a general row padding.
- `weekdayLetterSize`: only for the weekday letters of the schedule. Text elsewhere takes a text style, not a size.
- `weekdayDot`: only for the dot under a weekday in the schedule. Nothing else needs to build a dot this size.
- `weekdayChosenCircle`: only for the circle behind a chosen weekday in the schedule. Do not use it for another marker.
- `tipGap`: only for `TipCard`, as the gap between its icon, text and dismiss button. Do not use it in a screen.
- `tipInset`: only for `TipCard`, as the trailing inset beside its dismiss button. Do not use it in a screen.
- `tipIcon`: only for `TipCard`, as the size of its icon. Do not use it to size another symbol.
- `tipIconNudge`: only for `TipCard`, as the small drop that lines its icon up with the title. Do not use it to nudge another symbol.
- `tipDismissGlyph`: only for `TipCard`, as the size of its dismiss glyph. Do not use it to size another button's symbol.
- `emptyStateGap`: the gap between the parts of an empty state on Today and History. Do not write one, and see the note at the end.
- `emptyStateIconGap`: the gap under an empty state's mark or icon. Do not write one, and see the note at the end.
- `emptyStateTextGap`: the gap between an empty state's title and its text. Do not write one, and see the note at the end.
- `emptyStateInset`: the side inset that keeps an empty state's text narrow. Do not write one, and see the note at the end.
- `emptyMarkWidth`: the width of the mark on Today's empty state. Do not use it to size another image.
- `aboutMarkWidth`: the width of the mark in the About block. Do not use it to size another image.
- `emptyTodayTop`: the space above Today's empty state when no recent chip shows. Today only, so do not use it for another screen.
- `emptyTodayTopBelowChip`: the space above Today's empty state under the recent chip. Today only, so do not use it for another screen.
- `emptyTodayBottom`: the space under Today's empty state. Today only, so do not use it for another screen.
- `twoLineRowHeight`: the height of a `TwoLineRow`, which it applies itself. Do not size a two-line row by hand.
- `twoLineRowPadding`: the vertical padding of a `TwoLineRow`, which it applies itself. Do not pad a two-line row yourself.
- `rowMinimumHeight`: the floor under every row height, and the height of a control the size of a row. Do not set a lower minimum.
- `recentRowHeight`: the height of the recent chips row on New Entry. Do not use it to size another row.
- `iconTile`: the size of an `IconTile`. Do not size a symbol tile yourself.
- `iconSymbol`: the size of the symbol inside an `IconTile`. Do not size that symbol yourself.
- `bottomClearance`: the room under the last block or the bottom button, applied by `bottomPrimaryButton` and `lastBlockClearance`. Use the modifiers before the token.
- `primaryButtonHeight`: the design height of the bottom primary button. Do not size a primary button yourself.
- `primaryButtonSystemPadding`: the padding the system adds around a prominent button's label. Only the label height below uses it, so do not use it in a screen.
- `primaryButtonLabelHeight`: the label height that gives a primary button its design height. Give a button label this minimum height and do not add your own padding.
- `repeatChipSystemPadding`: the padding the system adds around the repeat chip's label. Only the label height below uses it, so do not use it in a screen.
- `repeatChipLabelHeight`: the label height that gives the repeat chip a row-sized height. Use it for a chip of that kind and do not add your own padding.

## Corner tokens

- `Corner`: the only place under `App/` that writes a corner radius as a number. Do not write a radius in a screen.
- `card`: the card's look, as a fill colour, a corner number and a shape for a background. One line covers `Color`, `Corner` and `Shape`, so a card-like block takes the fill and `.card` as its shape. Do not write a rounded rectangle with a radius or name the card's asset.
- `iconTile`: the corner of an `IconTile`, as a `Corner` number, and the size of the tile as a `Spacing` token. One line covers both and the `IconTile` view. Do not round a tile with your own radius.

## Colour tokens

Write each token with the `Color.` prefix, since SwiftUI has its own `.tint`, `.separator` and `.fill` that mean
something else.

- `surface`: the page behind the cards, which `screenSpacing` applies. Do not paint a screen with a system background.
- `ink`: primary text and icons on a card, such as a row title. Do not name a label colour yourself.
- `ink2`: secondary text, row values and chevrons. Do not name a grey or a secondary label colour yourself.
- `separator`: the system hairline colour for a line you draw. Do not draw a line in a grey of your own.
- `tint`: the brand colour for chosen state, ticks and switches. Do not use `.accentColor` or a copy of the asset.
- `onTint`: text or symbols on top of `tint`. Do not use white.
- `soft`: the soft brand fill behind a highlighted block. Do not use `tint` at low opacity.
- `onSoft`: text or symbols on top of `soft`. Do not use `tint` for text on it.
- `fill`: the subtle fill behind a symbol tile or a small control. Do not use a grey with opacity.
- `track`: the empty track of a slider or bar. Use it, and not `fill`, so each can change on its own.
- `glass`: the system's glass, which is a material and not a `Color`. Use it for a surface that floats over content, and do not build a blurred background yourself.

## What does not exist yet

The app has no shared empty-state view and no shared sheet toolbar. Each screen that needs one builds it from the
spacing tokens above. This is a gap in the catalog, not a ban: when you build one that a second screen needs, extract it into `App/Design` and add its entry in
the same pull request.
