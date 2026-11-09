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
        FootnotedSection(footnote: Text("Levels are 0 to 10. Everything stays on this iPhone.")) {
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

    private var time: String {
        ClockText.text(for: entry.date, calendar: .current, locale: .current)
    }

    var body: some View {
        Button(action: onSelect) {
            // A concrete primary keeps the List button's tint off the hierarchical secondary texts below it.
            layout
                .foregroundStyle(Color.primary)
        }
        // The row's visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear }
                .accessibilityLabel(spokenLabel)
                .accessibilityIdentifier("entry-row-\(entry.kind.rawValue)")
        }
    }

    private var layout: some View {
        IconRow(
            symbol: RowSymbol.name(for: entry.kind),
            title: Text(entry.kind.displayName),
            time: time,
            detail: detail
        ) {
            Text(entry.severity.value, format: .number)
                .font(.body)
                .monospacedDigit()
        }
    }

    private var detail: String? {
        entry.kind.asksWhere ? entry.placeSummary.text : nil
    }

    private var spokenLabel: String {
        let places = entry.kind.asksWhere ? RecentEntry(entry).spokenPlaces : nil
        return EntryRowText.spokenLabel(
            kind: String(localized: entry.kind.displayName),
            time: time,
            places: places,
            severity: String(localized: entry.severity.spokenValue)
        )
    }
}
