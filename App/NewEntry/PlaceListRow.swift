// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

private enum PlaceListRowMetrics {
    static let pinSlotWidth: CGFloat = 20
    static let pinIconSize: CGFloat = 13
}

struct PlaceListRow: View {
    let place: PlaceID
    @Binding var draft: EntryDraft
    @Environment(ShortcutsModel.self) private var shortcuts
    @Environment(TipProgressModel.self) private var tipProgress

    var body: some View {
        let isSelected = draft.places.contains(place)
        let isPinned = shortcuts.isPinned(place)
        rowButton(isSelected: isSelected, isPinned: isPinned)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    togglePin(event: .pinChangedBySwipe)
                } label: {
                    Label(pinSwipeTitle(isPinned), systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
                }
                .tint(.accentColor)
                .accessibilityLabel(Text(pinActionTitle(isPinned)))
                .accessibilityIdentifier("pin-action-\(place.rawValue)")
            }
            .sensoryFeedback(.selection, trigger: isSelected)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("place-row-\(place.rawValue)")
    }

    private func rowButton(isSelected: Bool, isPinned: Bool) -> some View {
        Button {
            togglePlace(isSelected: isSelected)
        } label: {
            HStack {
                pinSlot(isPinned: isPinned)
                Text(place.displayName)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color("AccentColor"))
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityRepresentation {
            if isPinned {
                accessibleButton(isSelected: isSelected)
                    .accessibilityValue(Text("Pinned"))
            } else {
                accessibleButton(isSelected: isSelected)
            }
        }
        .contextMenu { pinMenuItems(isPinned: isPinned) }
    }

    private func accessibleButton(isSelected: Bool) -> some View {
        Button(place.displayName) {
            togglePlace(isSelected: isSelected)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("place-\(place.rawValue)")
    }

    @ViewBuilder
    private func pinMenuItems(isPinned: Bool) -> some View {
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

    private func pinSlot(isPinned: Bool) -> some View {
        Image(systemName: "pin.fill")
            .font(.system(size: PlaceListRowMetrics.pinIconSize))
            .foregroundStyle(.secondary)
            .opacity(isPinned ? 1 : 0)
            .frame(width: PlaceListRowMetrics.pinSlotWidth, alignment: .leading)
            .accessibilityHidden(true)
    }

    private func togglePlace(isSelected: Bool) {
        if !isSelected {
            tipProgress.recordPick(place)
        }
        draft.togglePlace(place)
    }

    private func togglePin(event: ShortcutEvent) {
        if shortcuts.isPinned(place) {
            shortcuts.unpin(place, event: event)
        } else {
            shortcuts.pin(place, event: event)
        }
    }

    private func pinActionTitle(_ isPinned: Bool) -> LocalizedStringResource {
        isPinned ? "Unpin shortcut" : "Pin as shortcut"
    }

    private func pinSwipeTitle(_ isPinned: Bool) -> LocalizedStringResource {
        isPinned ? "Unpin" : "Pin"
    }
}
