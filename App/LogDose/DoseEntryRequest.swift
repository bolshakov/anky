// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The dates a New Entry takes for a dose, fixed when it is asked for, so a minute passing while the sheet is open
/// does not move its limit.
struct DoseEntryRequest: Identifiable {
    let id = UUID()
    let dates: DoseEntryDates

    init(doseAt: Date) {
        dates = DoseEntryDates(doseAt: doseAt, now: .now)
    }
}

extension View {
    func doseEntrySheet(
        _ request: Binding<DoseEntryRequest?>,
        model: EntryLogModel,
        onDismiss: @escaping () -> Void = {},
        onSaved: @escaping () -> Void,
        onAdded: @escaping (Entry) -> Void
    ) -> some View {
        // #lizard forgives
        sheet(item: request, onDismiss: onDismiss) { request in
            NewEntryView(
                model: model,
                latestDate: request.dates.latest,
                startDate: request.dates.start,
                onSaved: onSaved,
                onAdded: onAdded
            )
        }
    }
}
