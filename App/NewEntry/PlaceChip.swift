import AnkyDomain
import SwiftUI

struct PlaceChip: View {
    let place: PlaceID
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var checkSize: CGFloat = 14

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkSize, weight: .heavy))
                }
                Text(place.displayName)
            }
            .font(.subheadline.weight(isSelected ? .bold : .regular))
            .foregroundStyle(isSelected ? Color("OnAccent") : .primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? Color("AccentColor") : Color("PageBackground"), in: Capsule())
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
