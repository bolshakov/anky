// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A row's time in a column as wide as the widest time the region writes, so the title after it starts at one x on
/// every row.
struct TimeColumn: View {
    let time: String

    var body: some View {
        ZStack(alignment: .trailing) {
            // AM and PM differ in width, so both meridiems are sampled.
            ForEach(sampleTimes, id: \.self) { sample in
                Text(sample).hidden()
            }
            Text(time).foregroundStyle(.secondary)
        }
        .font(.footnote)
        .monospacedDigit()
        .fixedSize()
    }

    private var sampleTimes: [String] {
        [12, 0].compactMap { hour in
            Calendar.current.date(bySettingHour: hour, minute: 59, second: 0, of: .now)
        }
        .map { ClockText.text(for: $0, calendar: .current, locale: .current) }
    }
}
