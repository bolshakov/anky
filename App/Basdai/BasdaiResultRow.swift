// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiResultRow: View {
    let result: BasdaiResult
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        ValueRow(Text(verbatim: date), value: Text(verbatim: score))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: date))
            .accessibilityValue(Text("Score \(score) out of 10"))
    }

    private var date: String {
        BasdaiDateText.text(for: result.date, calendar: calendar, locale: locale)
    }

    private var score: String {
        BasdaiScore.text(of: result, locale: locale)
    }
}
