import AnkyDomain
import SwiftUI

private enum PlaceListRowMetrics {
    static let leadingInset: CGFloat = 16
    static let pinIconInset: CGFloat = 3
    static let pinIconSize: CGFloat = 11
}

struct PlaceListRow: View {
    let place: PlaceID
    @Binding var draft: EntryDraft
    @Environment(ShortcutsModel.self) private var shortcuts
    @Environment(TipProgressModel.self) private var tipProgress

    var body: some View {
        let isSelected = draft.places.contains(place)
        let isPinned = shortcuts.isPinned(place)
        PinSwipeRow(place: place, isPinned: isPinned, actions: pinActions) {
            rowButton(isSelected: isSelected, isPinned: isPinned)
                .overlay(alignment: .leading) { pinIcon(isPinned: isPinned) }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: PlaceListRowMetrics.leadingInset,
            bottom: 0,
            trailing: 16
        ))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("place-row-\(place.rawValue)")
    }

    private func rowButton(isSelected: Bool, isPinned: Bool) -> some View {
        Button {
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
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Button(place.displayName) {
                togglePlace(isSelected: isSelected)
            }
            .accessibilityValue(stateName(isSelected))
            .accessibilityIdentifier("place-\(place.rawValue)")
            .accessibilityAction(named: Text(pinActionTitle(isPinned))) {
                togglePin(event: .pinChangedByAction)
            }
        }
    }

    @ViewBuilder
    private func pinIcon(isPinned: Bool) -> some View {
        if isPinned {
            Image(systemName: "pin.fill")
                .font(.system(size: PlaceListRowMetrics.pinIconSize))
                .foregroundStyle(.secondary)
                .offset(x: PlaceListRowMetrics.pinIconInset - PlaceListRowMetrics.leadingInset)
                .accessibilityLabel("Pinned")
                .accessibilityIdentifier("pin-icon-\(place.rawValue)")
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
        isPinned ? "Unpin" : "Pin"
    }

    private func stateName(_ isSelected: Bool) -> LocalizedStringResource {
        isSelected ? "selected" : "not selected"
    }
}
