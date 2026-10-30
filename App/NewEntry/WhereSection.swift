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

            VStack(spacing: 0) {
                ChipFlowLayout {
                    ForEach(PlaceChips.shown(ranked: ranked, selected: draft.places), id: \.self) { place in
                        PlaceChip(place: place, isSelected: draft.places.contains(place)) {
                            draft.togglePlace(place)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                Divider()
                Button {
                    isShowingPlaces = true
                } label: {
                    HStack {
                        Text("More places")
                            .foregroundStyle(Color("AccentColor"))
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("more-places")
            }
            .background(Color("CardBackground"), in: .card)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("where-section")
    }
}
