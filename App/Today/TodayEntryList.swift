// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct TodayEntryList: View {
    let items: [LoggedItem]
    let medications: [Medication]
    let entries: [Entry]
    let onSelect: (Entry) -> Void
    let onSelectDose: (Dose) -> Void
    let onDelete: (Entry) -> Void
    let onDeleteDose: (Dose) -> Void

    var body: some View {
        Section {
            ForEach(items) { item in
                row(for: item)
            }
        } footer: {
            Text("Levels are 0 to 10. Stored on this iPhone only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
                title: DoseRowText.title(for: dose, in: medications)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    /// At accessibility sizes the time, the places with the kind, and the level stack in one column, so no word is
    /// squeezed into a narrow column.
    @ViewBuilder
    private var layout: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                timeText
                placeAndKind
                value
            }
        } else {
            HStack(spacing: 12) {
                TimeColumn(time: time)
                placeAndKind
                Spacer()
                value
            }
        }
    }

    private var timeText: some View {
        Text(time)
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }

    private var placeAndKind: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.placeSummary.text)
                .font(.body)
                .foregroundStyle(.primary)
            Text(entry.kind.displayName)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var spokenLabel: Text {
        let places = RecentEntry(entry).spokenPlaces
        return Text("\(time), \(places), \(Text(entry.kind.displayName)), \(Text(entry.severity.spokenValue))")
    }

    private var value: some View {
        Text(entry.severity.value, format: .number)
            .font(.body.weight(.semibold))
            .monospacedDigit()
    }
}
