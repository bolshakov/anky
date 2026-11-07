// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct WhereSection: View {
    @Binding var draft: EntryDraft
    @Binding var isShowingPlaces: Bool
    let chips: [PlaceID]

    var body: some View {
        CardSection(Text("Where"), id: "where") {
            ChipFlowLayout {
                ForEach(chips, id: \.self) { place in
                    PlaceChip(place: place, isSelected: draft.places.contains(place)) {
                        draft.togglePlace(place)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            MorePlacesRow(value: MorePlacesValue(selected: draft.places, chips: chips)) {
                isShowingPlaces = true
            }
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }
}
