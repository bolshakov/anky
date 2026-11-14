// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Today's `doc.text` button, which opens the Report screen. The toolbar copy leaves the button's look to the bar,
/// which already draws a glass circle round it.
struct ReportButton: View {
    let onReport: () -> Void
    var isInToolbar = false

    var body: some View {
        if isInToolbar {
            button(labelSide: nil)
        } else {
            button(labelSide: Spacing.glassCircleLabelSide)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .dynamicTypeSize(.large)
        }
    }

    private var label: some View {
        Label("Report for your doctor", systemImage: "doc.text").labelStyle(.iconOnly)
    }

    private func button(labelSide: CGFloat?) -> some View {
        Button(action: onReport) {
            if let labelSide {
                label.frame(width: labelSide, height: labelSide)
            } else {
                label
            }
        }
        .accessibilityIdentifier("report-button")
    }
}
