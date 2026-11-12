// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The report as it prints: a white page in the light palette whatever the app's appearance, laid out in PDF points.
/// Every page repeats the header, the Name line and the footer around its own content.
struct ReportPage: View {
    let size: ReportPageSize
    let headerLine: String
    let pageNumber: Int
    let pageCount: Int
    let content: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportPageHeader(headerLine: headerLine)
            ReportPageNameLine()
            content
            Spacer(minLength: 0)
            ReportPageFooter(pageNumber: pageNumber, pageCount: pageCount)
        }
        .padding(.horizontal, ReportMetrics.sideMargin)
        .padding(.top, ReportMetrics.topMargin)
        .padding(.bottom, ReportMetrics.bottomMargin)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(ReportPalette.paper)
        .foregroundStyle(ReportPalette.text)
        .environment(\.colorScheme, .light)
    }
}

struct ReportPageHeader: View {
    let headerLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: ReportMetrics.titleToLine) {
                    Text("Symptom report")
                        .font(.system(size: ReportMetrics.titleSize, weight: .bold))
                    Text(verbatim: headerLine)
                        .font(.system(size: ReportMetrics.smallSize))
                        .foregroundStyle(ReportPalette.secondary)
                }
                Spacer(minLength: ReportMetrics.columnGap)
                brand
            }
            .padding(.bottom, ReportMetrics.headerToRule)
            Rectangle()
                .fill(ReportPalette.text)
                .frame(height: ReportMetrics.headerRule)
        }
    }

    private var brand: some View {
        HStack(spacing: ReportMetrics.markToWord) {
            Image("AnkyMark")
                .resizable()
                .scaledToFit()
                .frame(height: ReportMetrics.markHeight)
                .foregroundStyle(Color.tint)
            Text(verbatim: "Anky")
                .font(.system(size: ReportMetrics.brandSize, weight: .semibold))
        }
    }
}

struct ReportPageNameLine: View {
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: ReportMetrics.labelToRule) {
            Text("Name line")
                .font(.system(size: ReportMetrics.bodySize))
                .foregroundStyle(ReportPalette.secondary)
            Rectangle()
                .fill(ReportPalette.secondary)
                .frame(height: ReportMetrics.hairline)
        }
        .padding(.top, ReportMetrics.nameTop)
        .padding(.bottom, ReportMetrics.sectionGap)
    }
}

struct ReportTotalsBand: View {
    let totals: ReportTotalsText

    var body: some View {
        VStack(spacing: 0) {
            ReportHairline()
            totalsRow.padding(.vertical, ReportMetrics.bandInset)
            ReportHairline()
        }
    }

    private var totalsRow: some View {
        HStack(alignment: .center, spacing: ReportMetrics.columnGap) {
            HStack(spacing: ReportMetrics.totalsGap) {
                Text(verbatim: totals.entries)
                Text(verbatim: totals.doses)
                if let firstEntry = totals.firstEntry {
                    Text(verbatim: firstEntry)
                }
            }
            .font(.system(size: ReportMetrics.totalsSize, weight: .semibold))
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text("Recorded by the patient in Anky.")
                Text("Counts, averages and ranges only.")
            }
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            .multilineTextAlignment(.trailing)
        }
    }
}

/// Each kind's severity by week, the charts sharing one week axis under the last of them.
struct ReportSeverityByWeek: View {
    let block: ReportSeverityBlock

    var body: some View {
        VStack(alignment: .leading, spacing: ReportMetrics.blockLineGap) {
            Text("Severity by week heading")
                .font(.system(size: ReportMetrics.totalsSize, weight: .semibold))
            if !block.charts.isEmpty {
                SeverityChartLegend()
                VStack(spacing: ReportMetrics.chartGap) {
                    ForEach(block.charts, id: \.kind) { chart in
                        SeverityWeekChart(
                            title: Text(chart.kind.displayName), weeks: chart.weeks, sentence: chart.sentence
                        )
                    }
                }
                WeekAxisRow(labels: block.axisLabels)
            }
            ForEach(block.noneLogged, id: \.self) { kind in
                HStack(spacing: 0) {
                    Text(kind.displayName)
                        .font(.system(size: SeverityChartMetrics.kindNameSize, weight: .semibold))
                        .frame(width: SeverityChartMetrics.plotLeading, alignment: .leading)
                    Text("Kind none logged")
                        .font(.system(size: ReportMetrics.bodySize))
                        .foregroundStyle(ReportPalette.secondary)
                }
            }
        }
    }
}

struct ReportHairline: View {
    var body: some View {
        Rectangle()
            .fill(ReportPalette.hairline)
            .frame(height: ReportMetrics.hairline)
    }
}

struct ReportPageFooter: View {
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        VStack(spacing: 0) {
            ReportHairline()
            HStack(alignment: .center, spacing: ReportMetrics.footerGap) {
                VStack(alignment: .leading, spacing: ReportMetrics.footerLineGap) {
                    Text("Anky is a personal log kept by the patient. It does not give medical advice.")
                    Text("Made with Anky, page \(pageNumber) of \(pageCount)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(alignment: .center, spacing: ReportMetrics.labelToRule) {
                    Text("Get Anky on the App Store")
                    ReportQRCode(side: ReportMetrics.qrSide)
                }
                .fixedSize()
            }
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            .padding(.top, ReportMetrics.footerInset)
        }
        .frame(height: ReportMetrics.footerHeight, alignment: .bottom)
    }
}

/// The page keeps the light values, since a printed page has no dark appearance.
enum ReportPalette {
    static let paper = Color.white
    static let text = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let secondary = Color(red: 0x44 / 255, green: 0x44 / 255, blue: 0x44 / 255)
    static let hairline = Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
}

/// PDF points, the boards' 96 dpi pixels times 0.75.
enum ReportMetrics {
    static let sideMargin: CGFloat = 36
    static let topMargin: CGFloat = 32
    static let bottomMargin: CGFloat = 26
    static let titleSize: CGFloat = 22
    static let brandSize: CGFloat = 13
    static let totalsSize: CGFloat = 12
    static let bodySize: CGFloat = 10
    static let smallSize: CGFloat = 8.5
    static let titleToLine: CGFloat = 4
    static let headerToRule: CGFloat = 9
    static let headerRule: CGFloat = 1.5
    static let hairline: CGFloat = 0.75
    static let markHeight: CGFloat = 22
    static let markToWord: CGFloat = 6
    static let columnGap: CGFloat = 18
    static let totalsGap: CGFloat = 18
    static let labelToRule: CGFloat = 6
    static let nameTop: CGFloat = 22
    static let sectionGap: CGFloat = 18
    static let blockLineGap: CGFloat = 8
    static let chartGap: CGFloat = 14
    static let bandInset: CGFloat = 9
    static let footerHeight: CGFloat = 60
    static let footerInset: CGFloat = 8
    static let footerLineGap: CGFloat = 3
    static let footerGap: CGFloat = 12
    static let qrSide: CGFloat = 48
}
