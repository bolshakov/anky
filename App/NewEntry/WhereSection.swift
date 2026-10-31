// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct WhereSection: View {
    @Binding var draft: EntryDraft
    @Binding var isShowingPlaces: Bool
    let chips: [PlaceID]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ChipFlowLayout {
                    ForEach(chips, id: \.self) { place in
                        PlaceChip(place: place, isSelected: draft.places.contains(place)) {
                            draft.togglePlace(place)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                Divider()
                MorePlacesRow(value: MorePlacesValue(selected: draft.places, chips: chips)) {
                    isShowingPlaces = true
                }
            }
            .background(Color("CardBackground"), in: .card)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("where-section")
    }
}
