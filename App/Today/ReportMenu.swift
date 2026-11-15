// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Today's `doc.text` button, which opens the Report screen. It lives in a toolbar, which draws the glass circle round
/// it.
struct ReportButton: View {
    let onReport: () -> Void

    var body: some View {
        Button(action: onReport) {
            Label("Report for your doctor", systemImage: "doc.text").labelStyle(.iconOnly)
        }
        .accessibilityIdentifier("report-button")
    }
}
