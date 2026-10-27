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
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            Text("Stored on this iPhone only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct EntryRow: View {
    let entry: Entry

    private var time: String {
        entry.date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(time)
                .foregroundStyle(.secondary)
            Text(entry.kind.title)
            Spacer()
            Text(entry.severity.text)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(time), \(entry.kind.title), \(entry.severity.text)")
        .accessibilityIdentifier("entry-row")
    }
}
