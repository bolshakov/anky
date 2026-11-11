// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct ScheduleRepeatSection: View {
    @Binding var schedule: ScheduleDraft

    var body: some View {
        CardSection(id: "schedule-repeat-section") {
            MenuRow(Text("Repeat"), selection: preset) {
                Text("Every day").tag(ScheduleDraft.Preset.everyDay)
                Text("Every week").tag(ScheduleDraft.Preset.everyWeek)
                Text("Every 2 weeks").tag(ScheduleDraft.Preset.everyTwoWeeks)
                Text("Every 4 weeks").tag(ScheduleDraft.Preset.everyFourWeeks)
                Text("Every month").tag(ScheduleDraft.Preset.everyMonth)
            }
            .accessibilityIdentifier("schedule-repeat")
        }
    }

    private var preset: Binding<ScheduleDraft.Preset> {
        Binding(get: { schedule.preset }, set: { schedule.choose($0) })
    }
}
