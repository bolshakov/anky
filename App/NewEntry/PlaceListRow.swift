// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

private enum PlaceListRowMetrics {
    static let nameLeadingInset: CGFloat = 32
    static let pinIconInset: CGFloat = 10
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
        PinSwipeRow(place: place, isPinned: isPinned, actions: pinActions) { isLifted in
            rowButton(isSelected: isSelected, isPinned: isPinned, isLifted: isLifted)
                .overlay(alignment: .leading) { pinIcon(isPinned: isPinned) }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .listRowInsets(EdgeInsets())
        .alignmentGuide(.listRowSeparatorLeading) { _ in PlaceListRowMetrics.nameLeadingInset }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("place-row-\(place.rawValue)")
    }

    private func rowButton(isSelected: Bool, isPinned: Bool, isLifted: Bool) -> some View {
        Button {
            // The finger that ends a swipe lifts on this button, and that lift is not a tap.
            guard !isLifted else { return }
            togglePlace(isSelected: isSelected)
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
            .padding(.trailing, 16)
            .foregroundStyle(.primary)
            .padding(.leading, PlaceListRowMetrics.nameLeadingInset)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            if isPinned {
                accessibleButton(isSelected: isSelected, isPinned: isPinned)
                    .accessibilityValue(Text("Pinned"))
            } else {
                accessibleButton(isSelected: isSelected, isPinned: isPinned)
            }
        }
        .contextMenu { pinMenuItems(isPinned: isPinned) }
    }

    private func accessibleButton(isSelected: Bool, isPinned: Bool) -> some View {
        Button(place.displayName) {
            togglePlace(isSelected: isSelected)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("place-\(place.rawValue)")
        .accessibilityAction(named: Text(pinActionTitle(isPinned))) {
            togglePin(event: .pinChangedByAction)
        }
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

    @ViewBuilder
    private func pinIcon(isPinned: Bool) -> some View {
        if isPinned {
            Image(systemName: "pin.fill")
                .font(.system(size: PlaceListRowMetrics.pinIconSize))
                .foregroundStyle(.secondary)
                .padding(.leading, PlaceListRowMetrics.pinIconInset)
                .accessibilityHidden(true)
        }
    }

    private var pinActions: PinSwipeActions {
        PinSwipeActions(
            onCrossedCommitPoint: { shortcuts.report(.crossedCommitPoint) },
            onAction: { togglePin(event: .pinChangedByAction) },
            onCommit: { togglePin(event: .pinChangedByLongSwipe) }
        )
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
}
