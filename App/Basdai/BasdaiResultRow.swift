// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiResultRow: View {
    let result: BasdaiResult
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        LabeledContent {
            Text(verbatim: score)
                .foregroundStyle(Color.ink2)
        } label: {
            Text(verbatim: date)
                .foregroundStyle(Color.ink)
        }
        .rowHeight(Spacing.twoLineRowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(date). Score \(score)."))
    }

    private var date: String {
        BasdaiDateText.text(for: result.date, calendar: calendar, locale: locale)
    }

    private var score: String {
        BasdaiScore.text(of: result, locale: locale)
    }
}
