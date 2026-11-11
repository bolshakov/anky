// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// Edits the same `ScheduleDraft` as the Schedule screen under it, so going back needs no code.
struct ScheduleCustomView: View {
    @Binding var schedule: ScheduleDraft

    var body: some View {
        List {
            CardSection(id: "custom-every-section") {
                Stepper(value: $schedule.interval, in: 1 ... 99) {
                    HStack {
                        Text("Every").foregroundStyle(Color.ink)
                        Spacer()
                        count.foregroundStyle(Color.ink2)
                    }
                }
                .rowHeight()
                .accessibilityIdentifier("custom-every")
            }
            CardSection(id: "custom-unit-section") {
                Picker(selection: $schedule.unit) {
                    Text("Days").tag(ScheduleDraft.Unit.days)
                    Text("Weeks").tag(ScheduleDraft.Unit.weeks)
                    Text("Months").tag(ScheduleDraft.Unit.months)
                } label: {
                    Text("Every")
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("custom-unit")
            }
            if schedule.unit == .weeks {
                CardSection(id: "schedule-weekdays-section") { ScheduleWeekdayRow(weekdays: weekdays) }
            }
        }
        .screenSpacing()
        .navigationTitle("Custom…")
        .navigationBarTitleDisplayMode(.inline)
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

    private var count: Text {
        switch schedule.unit {
        case .days: Text("\(schedule.interval) days")
        case .weeks: Text("\(schedule.interval) weeks")
        case .months: Text("\(schedule.interval) months")
        }
    }
}
