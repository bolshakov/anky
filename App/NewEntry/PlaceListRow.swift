import AnkyDomain
import SwiftUI

struct PlaceListRow: View {
    let joint: Joint
    @Binding var draft: EntryDraft

    var body: some View {
        Group {
            if joint.isPaired {
                VStack(alignment: .leading, spacing: 8) {
                    Text(joint.displayName)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { sideButtons }
                        VStack(alignment: .leading, spacing: 8) { sideButtons }
                    }
                }
            } else {
                ForEach(joint.places, id: \.self) { place in
                    placeButton(place, title: joint.displayName)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("place-row-\(joint.rawValue)")
    }

    private var sideButtons: some View {
        ForEach(joint.places, id: \.self) { place in
            placeButton(place, title: sideName(of: place))
        }
    }

    /// Each side is a button with its full place name as the label, so VoiceOver never reads a bare "Left".
    private func placeButton(_ place: PlaceID, title: LocalizedStringResource) -> some View {
        let isSelected = draft.places.contains(place)
        return Button {
            draft.togglePlace(place)
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                }
                Text(title)
            }
            .font(.body.weight(isSelected ? .bold : .regular))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(place.displayName)
        .accessibilityValue(stateName(isSelected))
        .accessibilityIdentifier("place-\(place.rawValue)")
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private func sideName(of place: PlaceID) -> LocalizedStringResource {
        PlaceCatalog.side(of: place) == .left ? "Left" : "Right"
    }

    private func stateName(_ isSelected: Bool) -> LocalizedStringResource {
        isSelected ? "selected" : "not selected"
    }
}
