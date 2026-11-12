// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Charts
import SwiftUI

/// One kind's severity by week: its name, a 0 to 10 axis, and per week a bar with its whisker, a dot, or nothing,
/// with the entry count under it. VoiceOver reads it as the one `sentence` it is given.
struct SeverityWeekChart: View {
    let title: Text
    let weeks: [WeekFigures]
    let sentence: String

    var body: some View {
        GeometryReader { proxy in
            let slot = SeverityChartMetrics.slotWidth(rowWidth: proxy.size.width, weekCount: weeks.count)
            VStack(alignment: .leading, spacing: SeverityChartMetrics.plotToCounts) {
                HStack(spacing: 0) {
                    kindName
                    yAxis
                    plot(barWidth: SeverityChartMetrics.barWidth(slotWidth: slot))
                }
                .frame(height: SeverityChartMetrics.plotHeight)
                countRow(slotWidth: slot)
            }
        }
        .frame(height: SeverityChartMetrics.chartHeight)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: sentence))
    }

    private var kindName: some View {
        title
            .font(.system(size: SeverityChartMetrics.kindNameSize, weight: .semibold))
            .foregroundStyle(SeverityChartPalette.text)
            .lineLimit(1)
            .frame(width: SeverityChartMetrics.kindColumnWidth, alignment: .leading)
    }

    private var yAxis: some View {
        GeometryReader { proxy in
            ForEach(SeverityChartMetrics.yAxisValues, id: \.self) { value in
                Text(value, format: .number)
                    .font(.system(size: SeverityChartMetrics.axisLabelSize))
                    .foregroundStyle(SeverityChartPalette.secondary)
                    .fixedSize()
                    .frame(width: proxy.size.width - SeverityChartMetrics.yAxisLabelGap, alignment: .trailing)
                    .position(
                        x: (proxy.size.width - SeverityChartMetrics.yAxisLabelGap) / 2,
                        y: proxy.size.height * (1 - Double(value) / Double(SeverityChartMetrics.severityMax))
                    )
            }
        }
        .frame(width: SeverityChartMetrics.yAxisColumnWidth)
    }

    private func plot(barWidth: CGFloat) -> some View {
        Chart {
            SeverityMarks.baseline()
            SeverityMarks.guide()
            ForEach(weeks.indices, id: \.self) { index in
                SeverityMarks.week(weeks[index].mark, at: Double(index), barWidth: barWidth)
            }
        }
        .severityPlot(xDomain: -0.5 ... Double(weeks.count) - 0.5)
    }

    private func countRow(slotWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: SeverityChartMetrics.plotLeading)
            ForEach(weeks.indices, id: \.self) { index in
                WeekCountLabel(count: weeks[index].count)
                    .fixedSize()
                    .frame(width: slotWidth)
            }
        }
        .frame(height: SeverityChartMetrics.countRowHeight)
    }
}

/// The marks of a severity chart, which the legend draws too, so a sample there is the mark on the chart.
enum SeverityMarks {
    @ChartContentBuilder
    static func week(_ mark: WeekMark, at x: Double, barWidth: CGFloat) -> some ChartContent {
        if case let .single(value) = mark {
            dot(at: x, value: Double(value.value))
        }
        if case let .range(average, lowest, highest) = mark {
            bar(at: x, average: average, width: barWidth)
            whisker(at: x, lowest: Double(lowest.value), highest: Double(highest.value))
        }
    }

    static func bar(at x: Double, average: Double, width: CGFloat) -> some ChartContent {
        BarMark(x: .value("Week", x), yStart: .value("Severity", 0), yEnd: .value("Severity", average),
                width: .fixed(width))
            .foregroundStyle(SeverityChartPalette.fill)
    }

    static func whisker(at x: Double, lowest: Double, highest: Double) -> some ChartContent {
        RuleMark(x: .value("Week", x), yStart: .value("Severity", lowest), yEnd: .value("Severity", highest))
            .lineStyle(StrokeStyle(lineWidth: SeverityChartMetrics.whiskerWidth))
            .foregroundStyle(SeverityChartPalette.outline)
    }

    static func dot(at x: Double, value: Double) -> some ChartContent {
        PointMark(x: .value("Week", x), y: .value("Severity", value))
            .symbol {
                Circle()
                    .fill(SeverityChartPalette.fill)
                    .strokeBorder(SeverityChartPalette.outline, lineWidth: SeverityChartMetrics.outlineWidth)
                    .frame(width: SeverityChartMetrics.dotDiameter, height: SeverityChartMetrics.dotDiameter)
            }
    }

    static func guide() -> some ChartContent {
        RuleMark(y: .value("Severity", SeverityChartMetrics.guideValue))
            .lineStyle(StrokeStyle(lineWidth: SeverityChartMetrics.guideWidth, dash: SeverityChartMetrics.guideDash))
            .foregroundStyle(SeverityChartPalette.hairline)
    }

    static func baseline() -> some ChartContent {
        RuleMark(y: .value("Severity", 0))
            .lineStyle(StrokeStyle(lineWidth: SeverityChartMetrics.baselineWidth))
            .foregroundStyle(SeverityChartPalette.hairline)
    }
}

/// A week's entry count, or a dash for a week with none, which reads as nothing logged rather than a zero.
struct WeekCountLabel: View {
    let count: Int

    var body: some View {
        Group {
            if count > 0 {
                Text(count, format: .number)
            } else {
                Text("Week count none")
            }
        }
        .font(.system(size: SeverityChartMetrics.countSize))
        .foregroundStyle(SeverityChartPalette.text)
    }
}

extension View {
    /// A plot with no axes, grid or legend of its own, whose x domain maps each week index onto one equal slot.
    func severityPlot(xDomain: ClosedRange<Double>) -> some View {
        chartXScale(domain: xDomain, range: .plotDimension(padding: 0))
            .chartYScale(domain: 0 ... SeverityChartMetrics.severityMax, range: .plotDimension(padding: 0))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
    }
}
