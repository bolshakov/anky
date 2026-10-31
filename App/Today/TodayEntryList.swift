// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct TodayEntryList: View {
    let entries: [Entry]
    let onSelect: (Entry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    EntryRow(entry: entry) {
                        onSelect(entry)
                    }
                    if entry.id != entries.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color("CardBackground"), in: .card)

            Text("Stored on this iPhone only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
            .padding()
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
        .accessibilityIdentifier("entry-row-\(entry.kind.rawValue)")
    }

    private var spokenLabel: Text {
        let places = entry.placeSummary.text
        return Text("\(time), \(places), \(Text(entry.kind.displayName)), \(Text(entry.severity.spokenValue))")
    }

    private var value: some View {
        Text("\(Text(entry.severity.value, format: .number).bold().foregroundStyle(.primary)) of \(10)")
            .foregroundStyle(.secondary)
    }
}
