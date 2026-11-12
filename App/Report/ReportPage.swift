// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The report as it prints: a white page in the light palette whatever the app's appearance, laid out in PDF points.
struct ReportPage: View {
    let size: ReportPageSize
    let headerLine: String
    let totals: ReportTotalsText
    let pageNumber: Int
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            nameLine
            totalsBand
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, Metrics.sideMargin)
        .padding(.top, Metrics.topMargin)
        .padding(.bottom, Metrics.bottomMargin)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(Palette.paper)
        .foregroundStyle(Palette.text)
        .environment(\.colorScheme, .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Metrics.titleToLine) {
                    Text("Symptom report")
                        .font(.system(size: Metrics.titleSize, weight: .bold))
                    Text(verbatim: headerLine)
                        .font(.system(size: Metrics.smallSize))
                        .foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: Metrics.columnGap)
                brand
            }
            .padding(.bottom, Metrics.headerToRule)
            Rectangle()
                .fill(Palette.text)
                .frame(height: Metrics.headerRule)
        }
    }

    private var brand: some View {
        HStack(spacing: Metrics.markToWord) {
            Image("AnkyMark")
                .resizable()
                .scaledToFit()
                .frame(height: Metrics.markHeight)
                .foregroundStyle(Color.tint)
            Text(verbatim: "Anky")
                .font(.system(size: Metrics.brandSize, weight: .semibold))
        }
    }

    private var nameLine: some View {
        HStack(alignment: .lastTextBaseline, spacing: Metrics.labelToRule) {
            Text("Name line")
                .font(.system(size: Metrics.bodySize))
                .foregroundStyle(Palette.secondary)
            Rectangle()
                .fill(Palette.secondary)
                .frame(height: Metrics.hairline)
        }
        .padding(.top, Metrics.nameTop)
        .padding(.bottom, Metrics.sectionGap)
    }

    private var totalsBand: some View {
        VStack(spacing: 0) {
            hairline
            totalsRow.padding(.vertical, Metrics.bandInset)
            hairline
        }
    }

    private var totalsRow: some View {
        HStack(alignment: .center, spacing: Metrics.columnGap) {
            HStack(spacing: Metrics.totalsGap) {
                Text(verbatim: totals.entries)
                Text(verbatim: totals.doses)
                if let firstEntry = totals.firstEntry {
                    Text(verbatim: firstEntry)
                }
            }
            .font(.system(size: Metrics.totalsSize, weight: .semibold))
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text("Recorded by the patient in Anky.")
                Text("Counts, averages and ranges only.")
            }
            .font(.system(size: Metrics.smallSize))
            .foregroundStyle(Palette.secondary)
            .multilineTextAlignment(.trailing)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: Metrics.hairline)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            hairline
            HStack(alignment: .center, spacing: Metrics.columnGap) {
                VStack(alignment: .leading, spacing: Metrics.footerLineGap) {
                    Text("Anky is a personal log kept by the patient. It does not give medical advice.")
                    Text("Made with Anky, page \(pageNumber) of \(pageCount)")
                }
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: Metrics.labelToRule) {
                    Text("Get Anky on the App Store")
                        .multilineTextAlignment(.trailing)
                    ReportQRCode(side: Metrics.qrSide)
                }
            }
            .font(.system(size: Metrics.smallSize))
            .foregroundStyle(Palette.secondary)
            .padding(.top, Metrics.footerInset)
        }
        .frame(height: Metrics.footerHeight, alignment: .bottom)
    }
}

/// The page keeps the light values, since a printed page has no dark appearance.
private enum Palette {
    static let paper = Color.white
    static let text = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let secondary = Color(red: 0x44 / 255, green: 0x44 / 255, blue: 0x44 / 255)
    static let hairline = Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
}

/// PDF points, the boards' 96 dpi pixels times 0.75.
private enum Metrics {
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
    static let bandInset: CGFloat = 9
    static let footerHeight: CGFloat = 60
    static let footerInset: CGFloat = 8
    static let footerLineGap: CGFloat = 3
    static let qrSide: CGFloat = 48
}
