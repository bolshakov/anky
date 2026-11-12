// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The places the patient logged in the period, filled column by column: the first three on the left, the next three
/// on the right.
struct ReportPlacesBlock: View {
    let places: ReportPlaces

    var body: some View {
        VStack(alignment: .leading, spacing: ReportMetrics.headingToContent) {
            Text("Places logged")
                .font(.system(size: ReportMetrics.totalsSize, weight: .semibold))
            if places.shown.isEmpty {
                Text("None logged in this period")
                    .font(.system(size: ReportMetrics.bodySize))
                    .foregroundStyle(ReportPalette.secondary)
            } else {
                tables
                if places.moreCount > 0 {
                    Text(verbatim: ReportPlacesText.moreLine(count: places.moreCount, locale: .current, bundle: .main))
                        .font(.system(size: ReportMetrics.smallSize))
                        .foregroundStyle(ReportPalette.secondary)
                }
            }
        }
    }

    private var tables: some View {
        HStack(alignment: .top, spacing: ReportMetrics.columnGap) {
            ReportPlacesTable(rows: Array(places.shown.prefix(ReportMetrics.placesPerTable)))
            let right = Array(places.shown.dropFirst(ReportMetrics.placesPerTable))
            if right.isEmpty {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            } else {
                ReportPlacesTable(rows: right)
            }
        }
    }
}

private struct ReportPlacesTable: View {
    let rows: [ReportPlaceCount]

    var body: some View {
        VStack(spacing: 0) {
            row(Text("Place"), Text("Entries"))
                .font(.system(size: ReportMetrics.smallSize))
                .foregroundStyle(ReportPalette.secondary)
            ReportHairline()
            ForEach(rows, id: \.place) { place in
                row(Text(verbatim: place.name), Text(place.count, format: .number))
                    .font(.system(size: ReportMetrics.bodySize))
                ReportHairline()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ name: Text, _ count: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: ReportMetrics.labelToRule) {
            name.frame(maxWidth: .infinity, alignment: .leading)
            count.monospacedDigit()
        }
        .padding(.vertical, ReportMetrics.placeRowInset)
    }
}

extension ReportMetrics {
    static let headingToContent: CGFloat = 8
    static let placeRowInset: CGFloat = 4
    static let placesPerTable = 3
}
