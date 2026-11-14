// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A saved BASDAI result drawn as the shared row, a button that opens it: its time and what it covers, with its score
/// at the trailing edge.
struct BasdaiRow: View {
    let result: BasdaiResult
    let onSelect: () -> Void
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        Button(action: onSelect) {
            row
                // A concrete primary keeps the List button's tint off the hierarchical secondary texts below it.
                .foregroundStyle(Color.primary)
                .contentShape(Rectangle())
        }
        // The row's visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear.minimumTapTarget() }
                .accessibilityLabel(
                    BasdaiRowText.spokenLabel(for: result, words: .app, calendar: calendar, locale: locale)
                )
                .accessibilityIdentifier("basdai-result-row")
        }
    }

    private var row: some View {
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
    }
}
