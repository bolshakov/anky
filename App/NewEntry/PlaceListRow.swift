import AnkyDomain
import SwiftUI

struct PlaceListRow: View {
    let place: PlaceID
    @Binding var draft: EntryDraft

    var body: some View {
        let isSelected = draft.places.contains(place)
        Button {
            draft.togglePlace(place)
        } label: {
            HStack {
                Text(place.displayName)
                    .font(.body.weight(isSelected ? .semibold : .regular))
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
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Button(place.displayName) {
                draft.togglePlace(place)
            }
            .accessibilityValue(stateName(isSelected))
            .accessibilityIdentifier("place-\(place.rawValue)")
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("place-row-\(place.rawValue)")
    }

    private func stateName(_ isSelected: Bool) -> LocalizedStringResource {
        isSelected ? "selected" : "not selected"
    }
}
