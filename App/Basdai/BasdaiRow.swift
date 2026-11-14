// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A saved BASDAI result drawn as the shared row: its time and what it covers, with its score at the trailing edge.
struct BasdaiRow: View {
    let result: BasdaiResult
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        IconRow(
            symbol: RowSymbol.basdai,
            title: Text("BASDAI"),
            time: ClockText.text(for: result.date, calendar: calendar, locale: locale),
            detail: BasdaiRowWords.app.detail
        ) {
            Text(verbatim: BasdaiRowText.score(of: result, locale: locale))
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(Color.ink)
        }
        // The row's visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            BasdaiRowText.spokenLabel(for: result, words: .app, calendar: calendar, locale: locale)
        )
        .accessibilityIdentifier("basdai-result-row")
    }
}
