// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct RemindersSection: View {
    let settings: DailyReminderSettings
    let scheduler: DailyReminderScheduler

    var body: some View {
        CardSection(Text("Reminders"), id: "settings-reminders") {
            SwitchRow(Text("Daily reminder"), isOn: isOn)
                .accessibilityIdentifier("reminder-toggle")
        }
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
