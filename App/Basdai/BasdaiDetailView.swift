// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiDetailView: View {
    let result: BasdaiResult
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        List {
            CardSection(id: "basdai-detail-score") {
                row(Text("Score"), value: BasdaiScore.text(of: result, locale: locale), id: "basdai-detail-score-row")
            }
            CardSection(
                footnote: Text(
                    "Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994)."
                ),
                id: "basdai-detail-answers",
                footnoteID: "basdai-detail-footnote"
            ) {
                ForEach(Array(zip(BasdaiQuestion.all, result.answers)), id: \.0.number) { question, answer in
                    row(
                        Text(verbatim: question.shortName),
                        value: question.numberText(answer, locale: locale),
                        id: "basdai-detail-q\(question.number)"
                    )
                }
            }
        }
        .screenSpacing()
        .accessibilityIdentifier("basdai-detail-screen")
        .navigationTitle(BasdaiDateText.text(for: result.date, calendar: calendar, locale: locale))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: Text, value: String, id: String) -> some View {
        ValueRow(title, value: Text(verbatim: value))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
    }
}
