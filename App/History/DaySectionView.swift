// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DaySectionView: View {
    let section: DaySection
    let medications: [Medication]
    let onSelect: (Entry) -> Void
    let onDelete: (Entry) -> Void

    var body: some View {
        Section {
            ForEach(section.items) { item in
                row(for: item)
                    .listRowInsets(EdgeInsets())
            }
        } header: {
            title
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .cardCaption()
                .accessibilityIdentifier("day-header")
        }
    }

    @ViewBuilder
    private func row(for item: LoggedItem) -> some View {
        switch item {
        case let .entry(entry):
            EntryRow(entry: entry) {
                onSelect(entry)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete", role: .destructive) {
                    onDelete(entry)
                }
                .accessibilityIdentifier("history-delete")
            }
        case let .dose(dose):
            DoseRow(dose: dose, title: DoseRowText.title(for: dose, in: medications))
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
