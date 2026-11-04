// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DaySectionView: View {
    let section: DaySection
    let medications: [Medication]
    let entries: [Entry]
    let waiting: Set<UUID>
    let onSelect: (Entry) -> Void
    let onSelectDose: (Dose) -> Void
    let onDelete: (Entry) -> Void
    let onDeleteDose: (Dose) -> Void

    var body: some View {
        Section {
            ForEach(section.items) { item in
                row(for: item)
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
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete", role: .destructive) {
                    onDeleteDose(dose)
                }
                .accessibilityIdentifier("history-delete")
            }
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
