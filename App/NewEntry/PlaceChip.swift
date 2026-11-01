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
        chipButton
            .frame(minHeight: 44)
            .contentShape(Capsule())
            .accessibilityLabel(place.displayName)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityAction(named: Text(pinActionName)) {
                togglePin(event: .pinChangedByAction)
            }
            .accessibilityIdentifier("place-chip-\(place.rawValue)")
            .sensoryFeedback(.selection, trigger: isSelected)
            .contextMenu {
                pinMenuItem
            }
    }

    @ViewBuilder
    private var chipButton: some View {
        let button = Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkSize, weight: .heavy))
                }
                Text(place.displayName)
            }
            .font(.subheadline)
        }
        .buttonBorderShape(.capsule)
        if isSelected {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var pinMenuItem: some View {
        if isPinned {
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
