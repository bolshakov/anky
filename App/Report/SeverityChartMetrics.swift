// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// The sizes a severity chart, its legend and the week axis row share, in PDF points. The plot of every chart starts
/// `plotLeading` from the row's left edge and splits the rest into equal week slots, so a row laid out from these
/// numbers alone lines up with the weeks of any chart above it.
enum SeverityChartMetrics {
    static let kindColumnWidth: CGFloat = 56
    static let yAxisColumnWidth: CGFloat = 16
    static let yAxisLabelGap: CGFloat = 4
    static var plotLeading: CGFloat {
        kindColumnWidth + yAxisColumnWidth
    }

    static let plotHeight: CGFloat = 48
    static let plotToCounts: CGFloat = 3
    static let countRowHeight: CGFloat = 10
    static var chartHeight: CGFloat {
        plotHeight + plotToCounts + countRowHeight
    }

    static let axisRowHeight: CGFloat = 12

    static let severityMax = 10
    static let yAxisValues = [0, 5, 10]
    static let guideValue = 5

    static let barWidthCap: CGFloat = 16.5
    static let barToSlot: CGFloat = 0.5
    static let whiskerWidth: CGFloat = 1
    static let dotDiameter: CGFloat = 6
    static let outlineWidth: CGFloat = 0.75
    static let guideWidth: CGFloat = 0.75
    static let guideDash: [CGFloat] = [1.5, 1.5]
    static let baselineWidth: CGFloat = 0.75

    static let kindNameSize: CGFloat = 9
    static let axisLabelSize: CGFloat = 8
    static let countSize: CGFloat = 8
    static let legendSize: CGFloat = 8.5

    static let legendMarkSide: CGFloat = 10
    static let legendMarkToWord: CGFloat = 3
    static let legendItemGap: CGFloat = 12

    static func slotWidth(rowWidth: CGFloat, weekCount: Int) -> CGFloat {
        guard weekCount > 0 else { return 0 }
        return max(rowWidth - plotLeading, 0) / CGFloat(weekCount)
    }

    static func barWidth(slotWidth: CGFloat) -> CGFloat {
        min(barWidthCap, slotWidth * barToSlot)
    }
}

/// The light values whatever the app's appearance, since a printed page has no dark appearance.
enum SeverityChartPalette {
    static let text = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let secondary = Color(red: 0x44 / 255, green: 0x44 / 255, blue: 0x44 / 255)
    static let hairline = Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
    static let outline = Color.black
    static var fill: Color {
        Color.tint
    }
}
