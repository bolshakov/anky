// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct ScheduleFootnote: View {
    let schedule: ScheduleDraft

    var body: some View {
        if let text {
            FootnotedSection(footnote: Text(verbatim: text)) {}
                .accessibilityIdentifier("schedule-footnote")
        }
    }

    private var text: String? {
        schedule.schedule().map {
            MedicationScheduleLine.footnote(
                schedule: $0, now: .now, locale: .current, calendar: .current, bundle: .main
            )
        }
    }
}
