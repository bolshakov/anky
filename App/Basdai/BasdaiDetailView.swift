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
                Text("Answers"),
                footnote: footnote,
                id: "basdai-detail-answers",
                footnoteID: "basdai-detail-footnote"
            ) {
                ForEach(Array(zip(BasdaiQuestion.all, result.answers)), id: \.0.number) { question, answer in
                    answerRow(question, answer)
                }
            }
        }
        .screenSpacing()
        .accessibilityIdentifier("basdai-detail-screen")
        .navigationTitle(BasdaiDateText.text(for: result.date, calendar: calendar, locale: locale))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var footnote: Text {
        let scale = String(localized: "Levels are 0 to 10.", locale: locale)
        let citation = String(
            localized: """
            Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J\u{00A0}Rheumatol\u{00A0}1994).
            """,
            locale: locale
        )
        return Text(verbatim: "\(scale)\n\(citation)")
    }

    private func answerRow(_ question: BasdaiQuestion, _ answer: Int) -> some View {
        row(
            Text(verbatim: question.shortName),
            value: question.numberText(answer, locale: locale),
            id: "basdai-detail-q\(question.number)"
        )
        .accessibilityLabel(question.shortName)
        .accessibilityValue(question.spokenNumberText(answer, locale: locale))
    }

    private func row(_ title: Text, value: String, id: String) -> some View {
        ValueRow(title, value: Text(verbatim: value))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(id)
    }
}
