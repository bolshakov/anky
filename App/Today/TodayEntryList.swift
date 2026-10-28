import AnkyDomain
import SwiftUI

struct TodayEntryList: View {
    let entries: [Entry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ForEach(entries) { entry in
                    EntryRow(entry: entry)
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

private struct EntryRow: View {
    let entry: Entry

    private var time: Text {
        Text(entry.date, format: Date.FormatStyle(date: .omitted, time: .shortened))
    }

    var body: some View {
        HStack(spacing: 12) {
            time
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.kind.displayName)
            Spacer()
            value
        }
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(time), \(Text(entry.kind.displayName)), \(Text(entry.severity.spokenValue))"))
        .accessibilityIdentifier("entry-row-\(entry.kind.rawValue)")
    }

    private var value: some View {
        Text("\(Text(entry.severity.value, format: .number).bold().foregroundStyle(.primary)) of \(10)")
            .foregroundStyle(.secondary)
    }
}
