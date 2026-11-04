// SPDX-License-Identifier: GPL-3.0-or-later
import UIKit
import XCTest

/// The colour of a button's words as drawn, read from the button's screenshot because the test cannot see the style.
struct LabelColour {
    struct RGB {
        let red: Double
        let green: Double
        let blue: Double
    }

    let background: RGB
    let label: RGB

    /// On a 0 to 1 scale.
    var luminance: Double {
        (0.2126 * label.red + 0.7152 * label.green + 0.0722 * label.blue) / 255
    }

    var isDark: Bool {
        luminance < 0.35
    }

    /// The WCAG contrast ratio between the label and its fill, from 1 to 21.
    var contrast: Double {
        let lighter = max(relativeLuminance(label), relativeLuminance(background))
        let darker = min(relativeLuminance(label), relativeLuminance(background))
        return (lighter + 0.05) / (darker + 0.05)
    }
}

enum LabelColourError: Error {
    case noLabelPixels(String)
}

/// The inset keeps the button's rounded corners and edges out of the sample.
private let insetHorizontalPoints = 22.0
private let insetVerticalPoints = 12.0

/// WCAG relative luminance, which the contrast ratio is built from.
private func relativeLuminance(_ colour: LabelColour.RGB) -> Double {
    func linear(_ channel: Double) -> Double {
        let scaled = channel / 255
        return scaled <= 0.03928 ? scaled / 12.92 : pow((scaled + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(colour.red) + 0.7152 * linear(colour.green) + 0.0722 * linear(colour.blue)
}

/// Pixels whose summed channel difference from the fill exceeds this count as label.
private let labelThreshold = 200

private struct Pixel: Hashable {
    let red: Int
    let green: Int
    let blue: Int

    func distance(to other: Pixel) -> Int {
        abs(red - other.red) + abs(green - other.green) + abs(blue - other.blue)
    }
}

@MainActor
func labelColour(of element: XCUIElement, threshold: Int = labelThreshold) throws -> LabelColour {
    let image = try XCTUnwrap(element.screenshot().image.cgImage)
    let scale = Double(image.width) / Double(element.frame.width)
    let dx = (insetHorizontalPoints * scale).rounded()
    let dy = (insetVerticalPoints * scale).rounded()
    let inset = CGRect(x: dx, y: dy, width: Double(image.width) - 2 * dx, height: Double(image.height) - 2 * dy)
    let samples = try pixels(of: XCTUnwrap(image.cropping(to: inset)))

    let counts = Dictionary(samples.map { ($0, 1) }, uniquingKeysWith: +)
    let fill = try XCTUnwrap(counts.max { $0.value < $1.value }?.key)
    let label = samples.filter { $0.distance(to: fill) > threshold }
    guard !label.isEmpty else { throw LabelColourError.noLabelPixels(element.identifier) }
    return LabelColour(background: rgb(of: fill), label: mean(of: label))
}

/// Polls until the label reads as `dark` says, so a screen that is still drawing is not read early. Returns the last
/// reading when the time runs out, so the caller's assertion shows what it read.
@MainActor
func settledLabelColour(of element: XCUIElement, dark: Bool, timeout: TimeInterval = 5) throws -> LabelColour {
    let deadline = Date.now.addingTimeInterval(timeout)
    var reading = try labelColour(of: element)
    while reading.isDark != dark, Date.now < deadline {
        Thread.sleep(forTimeInterval: 0.2)
        reading = try labelColour(of: element)
    }
    return reading
}

private func pixels(of image: CGImage) throws -> [Pixel] {
    let width = image.width
    let height = image.height
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    try bytes.withUnsafeMutableBytes { buffer in
        let context = try XCTUnwrap(CGContext(
            data: buffer.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return stride(from: 0, to: bytes.count, by: 4).map { offset in
        Pixel(red: Int(bytes[offset]), green: Int(bytes[offset + 1]), blue: Int(bytes[offset + 2]))
    }
}

private func rgb(of pixel: Pixel) -> LabelColour.RGB {
    .init(red: Double(pixel.red), green: Double(pixel.green), blue: Double(pixel.blue))
}

private func mean(of pixels: [Pixel]) -> LabelColour.RGB {
    let count = Double(pixels.count)
    return .init(
        red: Double(pixels.reduce(0) { $0 + $1.red }) / count,
        green: Double(pixels.reduce(0) { $0 + $1.green }) / count,
        blue: Double(pixels.reduce(0) { $0 + $1.blue }) / count
    )
}
