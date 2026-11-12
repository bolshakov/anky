// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

/// Sizes a piece of the report with the same layout the PDF renderer draws, so page breaks match the drawn page.
@MainActor enum ReportMeasure {
    static func height(of view: some View, width: CGFloat) -> CGFloat {
        let controller = UIHostingController(rootView: view.frame(width: width))
        return controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}
