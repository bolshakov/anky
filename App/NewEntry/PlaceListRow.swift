import AnkyDomain
import SwiftUI

struct PlaceListRow: View {
    let joint: Joint
    @Binding var draft: EntryDraft

    var body: some View {
        Group {
            if joint.isPaired {
                pairedRow
            } else {
                ForEach(joint.places, id: \.self) { place in
                    singleRow(place)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: joint.isPaired ? 12 : 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("place-row-\(joint.rawValue)")
    }

    private var pairedRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                Text(joint.displayName)
                Spacer(minLength: 8)
                sideChips
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(joint.displayName)
                HStack(spacing: 8) { sideChips }
            }
        }
        .padding(.vertical, 4)
    }

    private func singleRow(_ place: PlaceID) -> some View {
        let isSelected = draft.places.contains(place)
        return placeButton(place, isSelected: isSelected) {
            HStack {
                Text(joint.displayName)
                    .font(.body.weight(isSelected ? .bold : .regular))
                Spacer(minLength: 8)
                Image(systemName: "checkmark")
                    .font(.body.weight(.heavy))
                    .foregroundStyle(Color("AccentColor"))
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
    }

    private var sideChips: some View {
        ForEach(joint.places, id: \.self) { place in
            sideChip(place)
        }
    }

    private func sideChip(_ place: PlaceID) -> some View {
        let isSelected = draft.places.contains(place)
        return placeButton(place, isSelected: isSelected) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.heavy))
                        .accessibilityHidden(true)
                }
                Text(sideName(of: place))
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color("OnAccent") : .primary)
            .padding(.horizontal, 12)
            .frame(minWidth: 64, minHeight: 44)
            .background(Color(isSelected ? "AccentColor" : "PageBackground"), in: Capsule())
            .contentShape(Capsule())
        }
    }

    /// Each button is labelled with its full place name, so VoiceOver never reads a bare "Left" or "Right".
    private func placeButton(
        _ place: PlaceID,
        isSelected: Bool,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button {
            draft.togglePlace(place)
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Button(place.displayName) {
                draft.togglePlace(place)
            }
            .accessibilityValue(stateName(isSelected))
            .accessibilityIdentifier("place-\(place.rawValue)")
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private func sideName(of place: PlaceID) -> LocalizedStringResource {
        PlaceCatalog.side(of: place) == .left ? "Left" : "Right"
    }

    private func stateName(_ isSelected: Bool) -> LocalizedStringResource {
        isSelected ? "selected" : "not selected"
    }
}
