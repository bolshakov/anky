// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct RemindersSection: View {
    let settings: DailyReminderSettings
    let scheduler: DailyReminderScheduler

    var body: some View {
        CardSection(
            Text("Reminders"),
            footnote: Text("Skipped on days you have already logged something."),
            id: "settings-reminders"
        ) {
            SwitchRow(Text("Daily reminder"), isOn: isOn)
                .accessibilityIdentifier("reminder-toggle")
            if settings.isOn {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .foregroundStyle(Color.ink)
                    .rowHeight()
                    .accessibilityIdentifier("reminder-time")
            }
        }
    }

    private var time: Binding<Date> {
        Binding(
            get: { settings.time.date(on: .now, calendar: .current) },
            set: { settings.time = DailyReminderTime(date: $0, calendar: .current) }
        )
    }

    /// Turning on stays off until iOS grants permission, so a refusal leaves the switch off with nothing scheduled.
    private var isOn: Binding<Bool> {
        Binding(
            get: { settings.isOn },
            set: { wantsOn in
                guard wantsOn else {
                    settings.isOn = false
                    return
                }
                Task {
                    if await scheduler.requestPermission() {
                        settings.isOn = true
                    }
                }
            }
        )
    }
}
