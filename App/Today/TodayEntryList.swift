// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct TodayEntryList: View {
    let items: [LoggedItem]
    let medications: [Medication]
    let entries: [Entry]
    let waiting: Set<UUID>
    let onSelect: (Entry) -> Void
    let onSelectDose: (Dose) -> Void
    let onDelete: (Entry) -> Void
    let onDeleteDose: (Dose) -> Void

    var body: some View {
        CardSection(footnote: Text("Levels are 0 to 10. Everything stays on this iPhone."), id: "today-entries") {
            ForEach(items) { item in
                row(for: item)
            }
        }
    }

    @ViewBuilder
    private func row(for item: LoggedItem) -> some View {
        switch item {
        case let .entry(entry):
            EntryRow(entry: entry) {
                onSelect(entry)
            }
            .deleteSwipe {
                onDelete(entry)
            }
        case let .dose(dose):
            DoseRow(
                dose: dose,
                readings: DoseReadings(dose, in: entries),
                title: DoseRowText.title(for: dose, in: medications),
                isWaiting: waiting.contains(dose.id)
            ) {
                onSelectDose(dose)
            }
            .deleteSwipe {
                onDeleteDose(dose)
            }
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            // A concrete primary keeps the List button's tint off the hierarchical secondary texts below it.
            EntryIconRow(entry: entry)
                .foregroundStyle(Color.primary)
        }
        // The row's visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear }
                .accessibilityLabel(spokenLabel)
                .accessibilityIdentifier("entry-row-\(entry.kind.rawValue)")
        }
    }

    private var spokenLabel: String {
        EntryRowText.spokenLabel(
            kind: EntryIconRow.spokenKind(of: entry),
            time: EntryIconRow.time(of: entry),
            places: EntryIconRow.spokenPlaces(of: entry),
            severity: EntryIconRow.spokenLevel(of: entry)
        )
    }
}
