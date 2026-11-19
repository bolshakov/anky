The system route, with `.toolbarTitleDisplayMode(.inlineLarge)` on the three roots and Today's date kept in the list, put the title level with the Report icon on the bar's row with no empty row above it, and nothing custom was built.

### System route
Today, History and Settings set `.toolbarTitleDisplayMode(.inlineLarge)`. Today's date stays in the list's first block and does not go in `.navigationSubtitle`, because the walk showed a subtitle makes the system centre the Report icon on title plus date, 7 pt below the title line. On Today the title frame is y=63.7 with height 40.7 and the icon frame is y=66 with height 36, so both middles sit at y=84. `todayTopMargin` and its three tokens are gone, and the README rule now lets only these three roots set the display mode.

### Shared UI pieces
Today, History and Settings use `contentColumn` and the 16 pt `firstBlockTop` gap. Today takes the gap through the new `firstBlockClearance` in `App/Design`, which has a README entry. No screen sets a margin of its own.

### Look check
There is no design picture for this task. I checked light-mode screenshots by eye on a simulator: portrait, landscape, collapse on scroll, the largest type in English and Russian, and four pushed screens.

