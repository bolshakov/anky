// SPDX-License-Identifier: GPL-3.0-or-later
import QuickLook
import SwiftUI

/// The system preview of the report file, which brings Share, Print and Save to Files. The file is removed when the
/// preview goes away, however it is closed.
struct ReportPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        let dismiss = context.environment.dismiss
        preview.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close, primaryAction: UIAction { _ in dismiss() }
        )
        return UINavigationController(rootViewController: preview)
    }

    func updateUIViewController(_: UINavigationController, context _: Context) {}

    static func dismantleUIViewController(_: UINavigationController, coordinator _: Coordinator) {
        ReportPDFFile.remove()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in _: QLPreviewController) -> Int {
            1
        }

        func previewController(_: QLPreviewController, previewItemAt _: Int) -> any QLPreviewItem {
            url as NSURL
        }
    }
}
