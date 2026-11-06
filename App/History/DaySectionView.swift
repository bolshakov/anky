// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DaySectionView: View {
    let section: DaySection
    let medications: [Medication]
    let entriesByID: EntriesByID
    let waiting: Set<UUID>
    let onSelect: (Entry) -> Void
    let onSelectDose: (Dose) -> Void
    let onDelete: (Entry) -> Void
    let onDeleteDose: (Dose) -> Void
    let isLastDay: Bool
    let hasOlderDays: Bool
    let onLastDayAppear: () -> Void

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
                .onAppear {
                    if isLastDay, hasOlderDays {
                        onLastDayAppear()
                    }
                }
        } footer: {
            if isLastDay, !hasOlderDays {
                Text("Levels are 0 to 10.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                readings: DoseReadings(dose, in: entriesByID),
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
