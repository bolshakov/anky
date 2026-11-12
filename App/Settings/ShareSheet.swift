// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

/// The system share sheet for one file. `onClose` runs when the person shares, cancels or swipes it away.
struct ShareSheet: UIViewControllerRepresentable {
    let file: URL
    let onClose: () -> Void

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onClose() }
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
