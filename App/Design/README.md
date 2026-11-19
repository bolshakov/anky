# The design catalog

Read this before you build or change anything a person sees. Each shared piece under `App/Design` has one line below:
when to use it, and what not to build instead. Find the piece by name here, and build a new one only when no line fits.
A line states why, so open the Swift file for what the piece takes.

This file changes in the same pull request as the piece it names. `scripts/ci/check-ui-catalog.sh` fails when a piece
has no entry line, or an entry line names no piece. One entry line covers every piece that shares its name.

## Rules

- Only the three tab roots, Today, History and Settings, set the title display mode, to `.toolbarTitleDisplayMode(.inlineLarge)`,
  so the large title sits level with the bar's actions and no empty row stays above it. Today's date stays in the
  list's first block and never goes in `.navigationSubtitle`, so the bar holds only the title and the icon and the
  system levels them. A pushed screen sets nothing and keeps the system's default for its navigation bar.
- A footnote goes in the footer of `CardSection` and never in an empty trailing section. A trailing section built
  only to hold the footnote sat about 42 pt from its card, away from the group it explains.
- A form confirms and cancels in the top bar: the system's ✓ (`saveToolbarItem`) at the right and the system's ✕
  (`discardConfirmation`) at the left, on iOS 26 or later, in portrait and landscape. A form pins no wide Save button
  at the bottom, since the ✓ and ✕ stay in reach whatever the scroll position and the keyboard.
- A screen takes no raw asset colour, no `Color("...")` and no UIKit colour. It uses the colour tokens below, which are
  the only place an asset is named.

## Sections

- `CardSection`: the default section of a card screen, with an optional label above and a left-aligned footnote below. Do not build a `Section` with its own card background, header style and footer inset.
- `FooterBlockSection`: a card section whose footer is a centred block of any views that scrolls with the list, such as the About block. Do not hand-build a footer for it, and use `CardSection` when the footer is only left-aligned text.
- `SectionLabel`: the header style of a section label. `CardSection` applies it already, so use it by hand only on a `Section` you build yourself, and never set a header's case and insets yourself.

## Rows

- `IconRow`: the one row that shows an entry, a dose or a reading, with a tile, two lines and a trailing item, and a semibold title for the chosen row of a list. Do not build a second row with a leading symbol, and label it in the wrapper, since it sets no accessibility label.
- `IconTile`: the small symbol tile that starts an `IconRow`, decoration that VoiceOver skips. Do not draw a tinted square behind a symbol yourself.
- `ValueRow`: a title with a value on the trailing side, with a chevron when it has an action. Do not build a `LabeledContent` row, and give it no action when it is the label of a `NavigationLink`, which draws its own chevron.
- `TwoLineRow`: a title over a subtitle with an optional value, with a chevron when it has an action. Use `ValueRow` when one line is enough, and do not stack two texts in a row yourself.
- `TintRow`: one row in a list where a single item is chosen, with the chosen one semibold and ticked, in a slot every row reserves so the tick stays in one place. It takes an optional second line, which makes it the same two-line row as `TwoLineRow`. Do not draw your own checkmark row or a tick in another colour.
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

- `contentColumn`: the column a List, Form or ScrollView keeps its content in, which `screenSpacing` and `readingScreenSpacing` apply already. A ScrollView measures a content margin from the safe area's edge, so pass `measuredFromSafeArea: true` for one; `readingScreenSpacing` does. Each side is the larger of the margin, that side's safe-area inset and the width past `contentMaxWidth` shared out, never their sum. Do not set a horizontal content margin or cap the width with a frame, which would cut the background and the scroll indicator.
- `insetBarColumn`: the same column for the content of a bottom `safeAreaInset` or `safeAreaBar`, which has no content margin. Do not pad a bar's content with `screenMargin`.
- `screenSpacing`: the margins, first-block offset, section gap and page background of a card list screen. Do not set content margins, section spacing or the scroll background on a screen yourself.
- `readingScreenSpacing`: the margins of a screen of running text that is not a card list, with room at the bottom. Do not reuse `screenSpacing` for it, since that one also hides the scroll background.
- `titleFlushClearance`: Today's list top margin of zero, so the date, the first block, sits as close under the large title as the system allows, 11.7 pt under the title's frame. Do not set a top content margin yourself, and never a negative one or a negative padding on the first row, which leave it clipped or undrawn at the bar's edge.
- `lastBlockClearance`: room under the last block of a list that has no bottom button. Do not add a bottom padding.
- `emptyStateTop`: the top space of an empty-state block, which takes an `EmptyStateTop` case and swaps to that case's narrow space in compact height, so a turn keeps the list's state. Do not pad an empty block's top or pass it a number, and never a negative one, which clips the block.
- `EmptyStateTop`: the cases `emptyStateTop` takes, one per empty block, each holding its regular-height and its compact-height value. Add a case for a new empty block and do not add a parameter for a number.
- `emptyStateListOffset`: on the `List` of an empty-state screen, takes the same `EmptyStateTop` case, whether the block shows and whether it starts the list, and in compact height gives up the list's section gap and, for a block that starts the list, its top margin while the block shows, so `emptyStateTop` alone sets the visible gap. Put it before `screenSpacing` or `blockGapBetweenSections`, since the one closest to the list wins. Do not set a section gap or a content margin on an empty screen yourself.
- `emptyStateMark`: the width of Today's mark in an empty state, smaller in compact height so the heading and hint move up. Do not set a width frame on the mark, and do not scale it, since scaling leaves its layout size.
- `blockGapBetweenSections`: the standard gap between sections for a list that is not set up by `screenSpacing`. Do not call `listSectionSpacing` with a number.
- `primaryButton`: the prominent style for a button, with its label colour set to match. Do not apply the glass prominent style yourself.
- `discardConfirmation`: the Cancel of a form, drawn as the system's ✕ and spoken "Cancel", the system confirmation that Cancel opens only when the form holds changes, and the swipe-down block while it does. Put it on the form's root view inside its `NavigationStack`, and do not add your own Cancel item, text button, dialog or `interactiveDismissDisabled`.
- `saveToolbarItem`: the form's Save as the system's ✓ in the top bar, spoken "Save" or the `label` it is given, such as Schedule's "Done", where `isEnabled` dims only the ✓. Put it on the form's root view inside its `NavigationStack`, next to `discardConfirmation`, and do not pin a wide Save button, style the ✓, or use `.disabled` on the form for it.

## Tips

- `TipCard`: the one look of every tip, with an icon, title, message and dismiss action. Do not build a tip from `Spacing` tokens, and do not set its colour, font or padding on a screen.
- `TipCardStyle`: the `TipViewStyle` that draws a TipKit tip with `TipCard` and invalidates the tip on dismiss. Pass it to `.tipViewStyle` and do not write a second style.

## Spacing tokens

Every spacing and size under `App/` is a `Spacing` token, so a screen writes no number for one. Add a token to
`Spacing.swift` when none fits.

- `Spacing`: the home of every spacing and size. Do not write a point value in a screen or in a piece.
- `screenMargin`: the smallest side distance of a screen's content, applied by the shared pieces. Content outside a list uses `insetBarColumn` and not the bare token. Do not write a horizontal padding number.
- `contentMaxWidth`: the widest the content column grows, which `contentColumn` and `insetBarColumn` apply. Do not write the number or cap a screen's width yourself.
- `firstBlockTop`: the gap between the navigation bar and the first block, which `screenSpacing` applies. Use it for the same gap in a stack that is not a list.
- `blockGap`: the gap between the blocks of a screen, applied by `screenSpacing`. Do not set a different section gap.
- `emptyBlockGap`: the space above History's empty state in regular height. A screen reaches it only through `emptyStateTop`, and only History's case does.
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
- `noteCardVerticalPadding`: the space above and below the text of the Note card, so its first and last lines clear the card's edge. Only the Note card uses it. Do not use it as a general row padding.
- `moreRowGap`: the gap between the parts of the more-places row. Do not reuse it for another row.
- `chipInnerGap`: the gap between the symbol and the text inside a chip. Do not write one.
- `chevronSlotWidth`: the width of a chevron slot in the more-places row. Other rows take `RowChevron` instead.
- `chevronSlotHeight`: the height of a chevron slot in the more-places row. Other rows take `RowChevron` instead.
- `tapTarget`: the minimum hit area of a control. `minimumTapTarget` applies it, so use the modifier before the token.
- `weekdayRowHeight`: the smallest height of the weekday picker row of the schedule, which grows past it. Only for that row. Do not use it for another row, which takes `rowHeight`.
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
- `emptyMarkWidth`: the width of the mark on Today's empty state in regular height. A screen reaches it only through `emptyStateMark`. Do not use it to size another image.
- `emptyMarkWidthCompact`: the width of that mark in compact height, 60% of `emptyMarkWidth`, so the whole empty Today fits above the tab bar in landscape. A screen reaches it only through `emptyStateMark`.
- `aboutMarkWidth`: the width of the mark in the About block. Do not use it to size another image.
- `emptyTodayTop`: the space above Today's empty state in regular height when no recent chip shows. A screen reaches it only through `emptyStateTop`, and only Today's case does.
- `emptyTodayTopBelowChip`: the space above Today's empty state in regular height under the recent chip. A screen reaches it only through `emptyStateTop`, and only Today's case does.
- `emptyMedicationsTop`: the space above Medications' empty state in regular height, which with the list's own first-block offset puts the block 96 pt below the top bar. A screen reaches it only through `emptyStateTop`, and only Medications' cases do.
- `emptyTodayTopCompact`: the space above Today's empty state in compact height when no recent chip shows, which with `emptyStateListOffset` puts the block 12 pt below the date line. A screen reaches it only through `emptyStateTop`.
- `emptyTodayTopBelowChipCompact`: the same under the recent chip, 12 pt below the chip. A screen reaches it only through `emptyStateTop`.
- `emptyHistoryTopCompact`: the space above History's empty state in compact height, which puts the block 12 pt below the top bar, where the inline title sits. A screen reaches it only through `emptyStateTop`.
- `emptyMedicationsTopCompact`: the space above Medications' empty state in compact height, which with `emptyStateListOffset` puts the block 12 pt below the top bar, or below the archived card. A screen reaches it only through `emptyStateTop`.
- `emptyTodayBottom`: the space under Today's empty state. Today only, so do not use it for another screen.
- `twoLineRowHeight`: the height of a `TwoLineRow`, which it applies itself. Do not size a two-line row by hand.
- `twoLineRowPadding`: the vertical padding of a `TwoLineRow`, which it applies itself. Do not pad a two-line row yourself.
- `checkmark`: the size of the tick in a `TintRow`, which it applies itself. Do not size a tick yourself.
- `rowMinimumHeight`: the floor under every row height, and the height of a control the size of a row. Do not set a lower minimum.
- `recentRowHeight`: the height of the recent chips row on New Entry. Do not use it to size another row.
- `iconTile`: the size of an `IconTile`. Do not size a symbol tile yourself.
- `iconSymbol`: the size of the symbol inside an `IconTile`. Do not size that symbol yourself.
- `bottomClearance`: the room under the last block, applied by `lastBlockClearance`. Use the modifiers before the token.
- `addButtonSide`: the width and height of Today's round (+) menu button, which keeps this size at every text size. Do not use it to size another button.
- `addButtonSystemPadding`: the padding the system adds around the (+) button's label. Only the label side below uses it, so do not use it in a screen.
- `addButtonLabelSide`: the label side that gives the (+) button its `addButtonSide` circle. Give the (+) label this size and do not add your own padding.
- `addButtonClearance`: the bottom content margin of a list that a round button floats over, so its last row ends above the button. One line covers the `View` modifier and the `Spacing` token. Do not use it for a list with no floating button, which takes `lastBlockClearance`.
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
- `destructive`: the system red for a delete control, which the app-wide `tint` would otherwise paint in the brand colour. Do not rely on `role: .destructive` alone for the colour, and do not name a red yourself.
- `onTint`: text or symbols on top of `tint`. Do not use white.
- `soft`: the soft brand fill behind a highlighted block. Do not use `tint` at low opacity.
- `onSoft`: text or symbols on top of `soft`. Do not use `tint` for text on it.
- `fill`: the subtle fill behind a symbol tile or a small control. Do not use a grey with opacity.
- `track`: the empty track of a slider or bar. Use it, and not `fill`, so each can change on its own.
- `glass`: the system's glass, which is a material and not a `Color`. Use it for a surface that floats over content, and do not build a blurred background yourself.

## What does not exist yet

The app has no shared empty-state view. Each screen that needs one builds it from the spacing tokens above, but the top
space and the mark size of an empty block are shared through `emptyStateTop` and `emptyStateMark`. This is a
gap in the catalog, not a ban: when you build one that a second screen needs, extract it into `App/Design` and add its
entry in the same pull request.
