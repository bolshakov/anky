// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// The week labels under the charts, one slot per axis week, each centred under its week's marks.
struct WeekAxisRow: View {
    let labels: [String?]

    var body: some View {
        GeometryReader { proxy in
            let slot = SeverityChartMetrics.slotWidth(rowWidth: proxy.size.width, weekCount: labels.count)
            HStack(spacing: 0) {
                Color.clear.frame(width: SeverityChartMetrics.plotLeading)
                ForEach(labels.indices, id: \.self) { index in
                    Text(verbatim: labels[index] ?? "")
                        .fixedSize()
                        .frame(width: slot)
                }
            }
        }
        .font(.system(size: SeverityChartMetrics.axisLabelSize))
        .foregroundStyle(SeverityChartPalette.secondary)
        .frame(height: SeverityChartMetrics.axisRowHeight)
        .accessibilityHidden(true)
    }
}
