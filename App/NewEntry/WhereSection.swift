import AnkyDomain
import SwiftUI

struct WhereSection: View {
    @Binding var draft: EntryDraft
    let ranked: [PlaceID]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)

            ChipFlowLayout {
                ForEach(PlaceChips.shown(ranked: ranked, selected: draft.places), id: \.self) { place in
                    PlaceChip(place: place, isSelected: draft.places.contains(place)) {
                        draft.togglePlace(place)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color("CardBackground"), in: .card)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("where-section")
    }
}
