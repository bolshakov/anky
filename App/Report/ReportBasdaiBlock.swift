// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A run of the BASDAI table's rows. The heading, the column header, each row and the key line carry their own
/// spacing, so each can be measured alone and their heights add up to the block's.
struct ReportBasdaiBlock: View {
    let rows: [ReportBasdaiRowText]
    let isContinued: Bool
    let showsKey: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportBasdaiHeading(isContinued: isContinued)
            ReportBasdaiColumnHeader()
            ForEach(rows.indices, id: \.self) { index in
                ReportBasdaiRowView(text: rows[index])
            }
            if showsKey {
                ReportBasdaiKeyLine()
            }
        }
    }
}

struct ReportBasdaiHeading: View {
    let isContinued: Bool

    var body: some View {
        Group {
            if isContinued {
                Text("BASDAI scores, continued")
            } else {
                Text("BASDAI scores")
            }
        }
        .font(.system(size: ReportMetrics.totalsSize, weight: .semibold))
        .padding(.bottom, ReportMetrics.headingToContent)
    }
}

struct ReportBasdaiColumnHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            ReportBasdaiColumns(
                date: Text("Date"),
                answers: (1 ... ReportMetrics.basdaiQuestionCount).map { Text("Q\($0)") },
                score: Text("Score")
            )
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            ReportHairline()
        }
    }
}

struct ReportBasdaiRowView: View {
    let text: ReportBasdaiRowText

    var body: some View {
        VStack(spacing: 0) {
            ReportBasdaiColumns(
                date: Text(verbatim: text.date),
                answers: text.answers.map { Text(verbatim: $0) },
                score: Text(verbatim: text.score).bold()
            )
            .font(.system(size: ReportMetrics.bodySize))
            .monospacedDigit()
            ReportHairline()
        }
    }
}

struct ReportBasdaiKeyLine: View {
    var body: some View {
        Text(verbatim: ReportBasdaiKey.text(locale: .current, bundle: .main))
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, ReportMetrics.headingToContent)
    }
}

/// The date in the column that takes what the fixed columns leave, then one cell per answer and the score. A row's
/// widths never depend on another row, so a table split across pages keeps its columns.
private struct ReportBasdaiColumns: View {
    let date: Text
    let answers: [Text]
    let score: Text

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: ReportMetrics.basdaiColumnGap) {
            date
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(answers.indices, id: \.self) { index in
                answers[index]
                    .frame(width: ReportMetrics.basdaiAnswerWidth, alignment: .trailing)
            }
            score
                .frame(width: ReportMetrics.basdaiScoreWidth, alignment: .trailing)
        }
        .padding(.vertical, ReportMetrics.basdaiRowInset)
    }
}

extension ReportMetrics {
    static let basdaiColumnGap: CGFloat = 8
    static let basdaiRowInset: CGFloat = 4
    static let basdaiAnswerWidth: CGFloat = 26
    static let basdaiScoreWidth: CGFloat = 40
    static let basdaiQuestionCount = 6
}
