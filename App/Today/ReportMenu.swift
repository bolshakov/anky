// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Today's `doc.text` menu. The BASDAI item joins the report item here. The toolbar copy leaves the button's look to
/// the bar, which already draws a glass circle round it.
struct ReportMenu: View {
    let onReport: () -> Void
    let onBasdai: () -> Void
    var isInToolbar = false

    var body: some View {
        if isInToolbar {
            menu(labelSide: nil)
        } else {
            menu(labelSide: Spacing.glassCircleLabelSide)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .dynamicTypeSize(.large)
        }
    }

    private var label: some View {
        Label("Report and BASDAI", systemImage: "doc.text").labelStyle(.iconOnly)
    }

    private func menu(labelSide: CGFloat?) -> some View {
        Menu {
            Button(action: onReport) {
                Label("Report for your doctor", systemImage: "doc.text")
            }
            .accessibilityIdentifier("report-for-doctor")
            Button(action: onBasdai) {
                Label("BASDAI", systemImage: "chart.bar")
            }
            .accessibilityIdentifier("basdai-menu-item")
        } label: {
            if let labelSide {
                label.frame(width: labelSide, height: labelSide)
            } else {
                label
            }
        }
        .accessibilityIdentifier("report-menu")
    }
}
