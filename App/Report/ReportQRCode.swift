// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// The QR code that opens the Anky site, made on the phone. Each module is a filled square in a path, so the PDF holds
/// it as vector and its edges stay sharp at any zoom or print size.
struct ReportQRCode: View {
    let side: CGFloat

    private static let modules = QRModules(message: ReportQRPayload.url)

    var body: some View {
        Self.modules
            .fill(Color.black)
            .frame(width: side, height: side)
            .background(Color.white)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: ReportQRPayload.label))
    }
}

/// A QR symbol as a square grid of dark modules, correction level M. Empty when the generator gives no image.
private struct QRModules: Shape {
    let count: Int
    let dark: [Bool]

    init(message: String) {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(message.utf8)
        filter.correctionLevel = "M"
        guard let image = filter.outputImage,
              let bitmap = CIContext().createCGImage(image, from: image.extent),
              let grid = Self.grid(of: bitmap)
        else {
            count = 0
            dark = []
            return
        }
        count = bitmap.width
        dark = grid
    }

    func path(in rect: CGRect) -> Path {
        guard count > 0 else { return Path() }
        let module = min(rect.width, rect.height) / CGFloat(count)
        var path = Path()
        for index in dark.indices where dark[index] {
            let column = index % count, row = index / count
            path.addRect(CGRect(
                x: rect.minX + CGFloat(column) * module, y: rect.minY + CGFloat(row) * module,
                width: module, height: module
            ))
        }
        return path
    }

    /// One gray byte per module, read row by row from the top, since the generator draws one pixel per module.
    private static func grid(of bitmap: CGImage) -> [Bool]? {
        let width = bitmap.width, height = bitmap.height
        guard width == height, width > 0 else { return nil }
        var pixels = [UInt8](repeating: 255, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.interpolationQuality = .none
            context.draw(bitmap, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? pixels.map { $0 < 128 } : nil
    }
}
