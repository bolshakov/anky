import AnkyDomain
import SwiftUI

struct DaySectionView: View {
    let section: DaySection
    let onSelect: (Entry) -> Void
    let onDelete: (Entry) -> Void

    var body: some View {
        Section {
            ForEach(section.entries) { entry in
                EntryRow(entry: entry) {
                    onSelect(entry)
                }
                .listRowInsets(EdgeInsets())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        onDelete(entry)
                    }
                    .accessibilityIdentifier("history-delete")
                }
            }
        } header: {
            title
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(nil)
                .accessibilityIdentifier("day-header")
        }
    }

    private var title: Text {
        switch section.header {
        case .today:
            Text("Today")
        case .yesterday:
            Text("Yesterday")
        case .date:
            Text(verbatim: section.header.dateText(calendar: .current, locale: .current) ?? "")
        }
    }
}
