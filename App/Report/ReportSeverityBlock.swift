// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// What the report's severity-by-week block draws: a chart for each kind with an entry in the period, a line for each
/// kind without, and the shared axis labels, one slot per week, `nil` where a week carries no label.
struct ReportSeverityBlock {
    struct Chart {
        let kind: EntryKind
        let weeks: [WeekFigures]
        let sentence: String
    }

    let charts: [Chart]
    let noneLogged: [EntryKind]
    let axisLabels: [String?]

    init(figures: ReportWeeklyFigures, locale: Locale, calendar: Calendar, bundle: Bundle) {
        charts = figures.kinds.filter(\.hasEntries).map { kind in
            Chart(
                kind: kind.kind,
                weeks: kind.weeks,
                sentence: ReportChartSentence.text(for: kind, bundle: bundle, locale: locale)
            )
        }
        noneLogged = figures.kinds.filter { !$0.hasEntries }.map(\.kind)
        let labelled = Set(ReportWeekAxis.labelledIndices(weekCount: figures.weekStarts.count))
        axisLabels = figures.weekStarts.indices.map { index in
            labelled.contains(index)
                ? ReportWeekAxis.label(for: figures.weekStarts[index], locale: locale, calendar: calendar)
                : nil
        }
    }
}
