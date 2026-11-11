// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// Writes every state it reaches to the form's draft, so the form's Cancel discards the changes and back needs no code.
struct ScheduleView: View {
    @Binding var draft: MedicationDraft
    @State private var schedule: ScheduleDraft

    init(draft: Binding<MedicationDraft>) {
        _draft = draft
        let calendar = Calendar.current
        _schedule = State(initialValue: draft.wrappedValue.schedule.map { ScheduleDraft($0, calendar: calendar) }
            ?? ScheduleDraft(startingOn: ScheduleDay(.now, in: calendar.timeZone), calendar: calendar))
    }

    var body: some View {
        List {
            ScheduleRepeatSection(schedule: $schedule)
            if schedule.unit == .weeks {
                CardSection(id: "schedule-weekdays-section") { ScheduleWeekdayRow(weekdays: weekdays) }
            }
            if schedule.unit == .months {
                CardSection(id: "schedule-day-section") { ScheduleOnDayRow(day: $schedule.dayOfMonth) }
            }
            ScheduleTimesSection(schedule: $schedule)
            ScheduleDurationSection(schedule: $schedule)
            ScheduleFootnote(schedule: schedule)
        }
        .screenSpacing()
        .accessibilityIdentifier("schedule-screen")
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if draft.schedule == nil {
                draft.schedule = schedule.schedule()
            }
        }
        .onChange(of: schedule) { _, changed in
            draft.schedule = changed.schedule()
        }
    }

    /// The row only says which weekday was tapped. `toggle` decides, so the last weekday stays on.
    private var weekdays: Binding<Set<Locale.Weekday>> {
        Binding(
            get: { schedule.weekdays },
            set: { changed in
                if let tapped = changed.symmetricDifference(schedule.weekdays).first {
                    schedule.toggle(tapped)
                }
            }
        )
    }
}
