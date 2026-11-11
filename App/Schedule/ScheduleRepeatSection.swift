// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct ScheduleRepeatSection: View {
    @Binding var schedule: ScheduleDraft

    var body: some View {
        CardSection(id: "schedule-repeat-section") {
            MenuRow(Text("Repeat"), selection: preset) {
                Text("Every day").tag(Optional(ScheduleDraft.Preset.everyDay))
                Text("Every week").tag(Optional(ScheduleDraft.Preset.everyWeek))
                Text("Every 2 weeks").tag(Optional(ScheduleDraft.Preset.everyTwoWeeks))
                Text("Every 4 weeks").tag(Optional(ScheduleDraft.Preset.everyFourWeeks))
            }
            .accessibilityIdentifier("schedule-repeat")
            if schedule.unit == .weeks {
                ScheduleWeekdayRow(weekdays: schedule.weekdays) { schedule.toggle($0) }
            }
        }
    }

    private var preset: Binding<ScheduleDraft.Preset?> {
        Binding(
            get: { schedule.preset },
            set: { chosen in
                if let chosen {
                    schedule.choose(chosen)
                }
            }
        )
    }
}
