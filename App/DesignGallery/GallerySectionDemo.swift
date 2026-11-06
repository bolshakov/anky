// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import SwiftUI

    struct GallerySectionDemo: View {
        var body: some View {
            CardSection(
                Text(verbatim: "Section label"),
                footnote: Text(verbatim: "A footnote under the card."),
                id: "gallery-section"
            ) {
                Text(verbatim: "A row in a card")
                    .rowHeight()
                    .accessibilityIdentifier("gallery-section-row")
            }
            CardSection(id: "gallery-bare") {
                Text(verbatim: "A bare row")
                    .rowHeight()
                    .accessibilityIdentifier("gallery-bare-row")
            }
        }
    }

    extension View {
        func galleryBottomBar() -> some View {
            bottomPrimaryButton(Text(verbatim: "Primary action"), id: "gallery-primary") {}
        }
    }
#endif
