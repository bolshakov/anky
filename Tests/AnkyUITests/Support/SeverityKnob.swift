// SPDX-License-Identifier: GPL-3.0-or-later
import XCTest

/// The system slider's accessibility frame includes its end labels, so the knob's travel starts an inset from that
/// frame's left edge and ends an inset from its right edge. Level 0 has the knob centre at the start and level 10 at
/// the end, in points at the default text size.
private let knobTravelStart: CGFloat = 34.7
private let knobTravelEndInset: CGFloat = 41.1

/// A point on the knob at a level, as a fraction of the slider's frame. Right-to-left mirrors the travel, so level 0
/// sits at the right end.
@MainActor
func knobCoordinate(of slider: XCUIElement, level: Int, rightToLeft: Bool = false) -> XCUICoordinate {
    let width = slider.frame.width
    let knobTravelEnd = width - knobTravelEndInset
    let fraction = knobTravelStart + (knobTravelEnd - knobTravelStart) * CGFloat(level) / 10
    let fromStart = rightToLeft ? width - fraction : fraction
    return slider.coordinate(withNormalizedOffset: CGVector(dx: fromStart / width, dy: 0.5))
}
