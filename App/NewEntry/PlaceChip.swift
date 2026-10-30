import AnkyDomain
import SwiftUI

struct PlaceChip: View {
    let place: PlaceID
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                }
                Text(place.displayName)
            }
            .font(.body.weight(isSelected ? .bold : .regular))
            .foregroundStyle(isSelected ? Color("OnAccent") : .primary)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(isSelected ? Color("AccentColor") : .clear, in: Capsule())
            .overlay {
                if !isSelected {
                    Capsule().strokeBorder(Color("AccentColor"), lineWidth: 1)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(place.displayName)
        .accessibilityValue(stateName)
        .accessibilityIdentifier("place-chip-\(place.rawValue)")
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var stateName: LocalizedStringResource {
        isSelected ? "selected" : "not selected"
    }
}
