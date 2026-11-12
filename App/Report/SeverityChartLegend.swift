// SPDX-License-Identifier: GPL-3.0-or-later
import Charts
import SwiftUI

/// The legend line over the severity charts, its samples drawn with the charts' own marks.
struct SeverityChartLegend: View {
    var body: some View {
        HStack(spacing: SeverityChartMetrics.legendItemGap) {
            item("Legend weekly average") {
                sample { SeverityMarks.bar(at: 0, average: Double(SeverityChartMetrics.severityMax), width: barWidth) }
            }
            item("Legend lowest to highest") {
                sample { SeverityMarks.whisker(at: 0, lowest: 0, highest: Double(SeverityChartMetrics.severityMax)) }
            }
            item("Legend one entry") {
                sample { SeverityMarks.dot(at: 0, value: Double(SeverityChartMetrics.guideValue)) }
            }
            Text("Legend number under a bar")
            item("Legend none logged") {
                WeekCountLabel(count: 0)
            }
        }
        .font(.system(size: SeverityChartMetrics.legendSize))
        .foregroundStyle(SeverityChartPalette.secondary)
        .accessibilityHidden(true)
    }

    private var barWidth: CGFloat {
        SeverityChartMetrics.legendMarkSide
    }

    private func item(_ words: LocalizedStringKey, @ViewBuilder mark: () -> some View) -> some View {
        HStack(spacing: SeverityChartMetrics.legendMarkToWord) {
            mark()
            Text(words)
        }
    }

    private func sample(@ChartContentBuilder _ content: () -> some ChartContent) -> some View {
        Chart { content() }
            .severityPlot(xDomain: -0.5 ... 0.5)
            .frame(width: SeverityChartMetrics.legendMarkSide, height: SeverityChartMetrics.legendMarkSide)
    }
}
