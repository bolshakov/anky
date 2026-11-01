// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct TodayEntryList: View {
    let items: [LoggedItem]
    let medications: [Medication]
    let onSelect: (Entry) -> Void

    var body: some View {
        Section {
            ForEach(items) { item in
                row(for: item)
            }
        } footer: {
            Text("Stored on this iPhone only.")
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
        case let .dose(dose):
            DoseRow(dose: dose, title: DoseRowText.title(for: dose, in: medications))
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    let onSelect: () -> Void

    private var time: Text {
        Text(entry.date, format: Date.FormatStyle(date: .omitted, time: .shortened))
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                time
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.placeSummary.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(entry.kind.displayName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                value
            }
            .contentShape(Rectangle())
        }
        // The row's visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear }
                .accessibilityLabel(spokenLabel)
                .accessibilityIdentifier("entry-row-\(entry.kind.rawValue)")
        }
    }

    private var spokenLabel: Text {
        let places = RecentEntry(entry).spokenPlaces
        return Text("\(time), \(places), \(Text(entry.kind.displayName)), \(Text(entry.severity.spokenValue))")
    }

    private var value: some View {
        Text("\(Text(entry.severity.value, format: .number).bold().foregroundStyle(.primary)) of \(10)")
            .foregroundStyle(.secondary)
    }
}
