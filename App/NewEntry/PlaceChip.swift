// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct PlaceChip: View {
    let place: PlaceID
    let isSelected: Bool
    let action: () -> Void

    @Environment(ShortcutsModel.self) private var shortcuts
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
        .accessibilityValue(isPinned ? String(localized: "Pinned") : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: Text(pinActionName)) {
            togglePin(event: .pinChangedByAction)
        }
        .accessibilityIdentifier("place-chip-\(place.rawValue)")
        .sensoryFeedback(.selection, trigger: isSelected)
        .contextMenu {
            if shortcuts.isPinned(place) {
                Button {
                    shortcuts.unpin(place, event: .pinChangedByMenu)
                } label: {
                    Label("Unpin shortcut", systemImage: "pin.slash.fill")
                }
            } else {
                Button {
                    shortcuts.pin(place, event: .pinChangedByMenu)
                } label: {
                    Label("Pin as shortcut", systemImage: "pin.fill")
                }
            }
        }
    }

    private var isPinned: Bool {
        shortcuts.isPinned(place)
    }

    private var pinActionName: LocalizedStringResource {
        isPinned ? "Unpin shortcut" : "Pin as shortcut"
    }

    private func togglePin(event: ShortcutEvent) {
        if isPinned {
            shortcuts.unpin(place, event: event)
        } else {
            shortcuts.pin(place, event: event)
        }
    }
}
