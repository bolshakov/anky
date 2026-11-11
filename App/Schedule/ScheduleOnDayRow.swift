// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ScheduleOnDayRow: View {
    @Binding var day: Int

    var body: some View {
        MenuRow(Text("On day"), selection: $day) {
            ForEach(1 ... 31, id: \.self) { number in
                Text(number, format: .number).tag(number)
            }
        }
        .accessibilityIdentifier("schedule-day-of-month")
    }
}
