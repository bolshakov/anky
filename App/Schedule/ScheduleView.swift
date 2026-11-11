// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// Writes every state it reaches to the form's draft, so the form's Cancel discards the changes and back needs no code.
struct ScheduleView: View {
    @Binding var draft: MedicationDraft
    @State private var schedule: ScheduleDraft
    @Environment(\.dismiss) private var dismiss

    init(draft: Binding<MedicationDraft>) {
        _draft = draft
        let calendar = Calendar.current
        _schedule = State(initialValue: draft.wrappedValue.schedule.map { ScheduleDraft($0, calendar: calendar) }
            ?? ScheduleDraft(startingOn: ScheduleDay(.now, in: calendar.timeZone), calendar: calendar))
    }

    var body: some View {
        List {
            ScheduleRepeatSection(schedule: $schedule)
            ScheduleTimesSection(schedule: $schedule)
            ScheduleDurationSection(schedule: $schedule)
            ScheduleFootnote(schedule: schedule)
        }
        .screenSpacing()
        .accessibilityIdentifier("schedule-screen")
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .bottomPrimaryButton(Text("Done"), id: "schedule-done") { dismiss() }
        .onAppear {
            if draft.schedule == nil {
                draft.schedule = schedule.schedule()
            }
        }
        .onChange(of: schedule) { _, changed in
            draft.schedule = changed.schedule()
        }
    }
}
