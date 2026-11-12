// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Today's `doc.text` toolbar menu. The BASDAI item joins the report item here.
struct ReportMenu: ToolbarContent {
    let onReport: () -> Void
    let onBasdai: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
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
                Label("Report and BASDAI", systemImage: "doc.text")
            }
            .accessibilityIdentifier("report-menu")
        }
    }
}
