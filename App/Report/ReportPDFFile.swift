// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

/// The one report file, in the temporary folder that device backups do not copy. It lives only while the preview
/// shows it.
@MainActor enum ReportPDFFile {
    static let url = FileManager.default.temporaryDirectory.appending(path: "Anky report.pdf")

    /// Draws each page as vector PDF, so its text stays text, and writes the file in one atomic step. On a failure no
    /// file is left.
    static func write(_ pages: [ReportPage]) throws -> URL {
        let data = UIGraphicsPDFRenderer().pdfData { context in
            for page in pages {
                draw(page, in: context)
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

    private static func draw(_ page: ReportPage, in context: UIGraphicsPDFRendererContext) {
        let bounds = CGRect(x: 0, y: 0, width: page.size.width, height: page.size.height)
        let renderer = ImageRenderer(content: page)
        // Edges snap to 1/scale points. At the default scale of 1 a line thinner than a point can round to nothing.
        renderer.scale = 4
        context.beginPage(withBounds: bounds, pageInfo: [:])
        context.cgContext.translateBy(x: 0, y: bounds.height)
        context.cgContext.scaleBy(x: 1, y: -1)
        renderer.render { _, draw in
            draw(context.cgContext)
        }
    }

    static func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
