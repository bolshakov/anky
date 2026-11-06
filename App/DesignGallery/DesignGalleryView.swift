// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import SwiftUI

    struct DesignGalleryView: View {
        var body: some View {
            List {
                GalleryFirstBlock()
                GallerySectionDemo()
                GalleryRowsDemo()
                Section {
                    Text(verbatim: "A plain row")
                        .rowHeight()
                        .accessibilityIdentifier("gallery-plain-row")
                }
            }
            .screenSpacing()
            .galleryBottomBar()
            .accessibilityIdentifier("design-gallery")
            .navigationTitle(Text(verbatim: "Pieces"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
#endif
