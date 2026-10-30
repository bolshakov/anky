import AnkyDomain
import SwiftUI

struct WhereSection: View {
    @Binding var draft: EntryDraft
    @Binding var isShowingPlaces: Bool
    let ranked: [PlaceID]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                ChipFlowLayout {
                    ForEach(PlaceChips.shown(ranked: ranked, selected: draft.places), id: \.self) { place in
                        PlaceChip(place: place, isSelected: draft.places.contains(place)) {
                            draft.togglePlace(place)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Button {
                    isShowingPlaces = true
                } label: {
                    HStack {
                        Text("More places")
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("more-places")
            }
            .padding(12)
            .background(Color("CardBackground"), in: .card)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("where-section")
    }
}
