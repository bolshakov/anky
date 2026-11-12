// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

/// The one report file, in the temporary folder that device backups do not copy. It lives only while the preview
/// shows it.
enum ReportPDFFile {
    static let url = FileManager.default.temporaryDirectory.appending(path: "Anky report.pdf")

    /// Draws `page` as vector PDF, so its text stays text, and writes it in one atomic step. On a failure no file is
    /// left.
    @MainActor static func write(_ page: ReportPage) throws -> URL {
        let bounds = CGRect(x: 0, y: 0, width: page.size.width, height: page.size.height)
        let renderer = ImageRenderer(content: page)
        // Edges snap to 1/scale points. At the default scale of 1 a line thinner than a point can round to nothing.
        renderer.scale = 4
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            context.beginPage()
            context.cgContext.translateBy(x: 0, y: bounds.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            renderer.render { _, draw in
                draw(context.cgContext)
            }
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            remove()
            throw error
        }
        return url
    }

    static func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
