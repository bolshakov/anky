// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import SwiftUI

    struct DesignGalleryView: View {
        @State private var primaryDisabled = false

        var body: some View {
            List {
                GalleryFirstBlock()
                GallerySectionDemo()
                CardSection(id: "gallery-primary-state") {
                    SwitchRow(Text(verbatim: "Disable primary action"), isOn: $primaryDisabled)
                        .accessibilityIdentifier("gallery-primary-disabled")
                }
                GalleryRowsDemo()
                Section {
                    Text(verbatim: "A plain row")
                        .rowHeight()
                        .accessibilityIdentifier("gallery-plain-row")
                }
            }
            .screenSpacing()
            .accessibilityIdentifier("design-gallery")
            .galleryBottomBar(isEnabled: !primaryDisabled)
            .navigationTitle(Text(verbatim: "Pieces"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
#endif
