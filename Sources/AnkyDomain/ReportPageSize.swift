// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// A report page in PDF points.
public struct ReportPageSize: Equatable, Sendable {
    public let width: Double, height: Double

    private static let usLetter = ReportPageSize(width: 612, height: 792)
    private static let a4 = ReportPageSize(width: 595.2, height: 841.8)

    private static let usLetterRegions: Set<Locale.Region> = [.unitedStates, .canada]

    public static func forRegion(_ region: Locale.Region?) -> ReportPageSize {
        guard let region, usLetterRegions.contains(region) else { return a4 }
        return usLetter
    }
}
