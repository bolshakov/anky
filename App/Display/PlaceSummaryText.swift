// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension PlaceSummary {
    var text: String {
        switch self {
        case .wholeBody: String(localized: "Whole body")
        case .noPlace: String(localized: "No place")
        case let .places(ids): ids.map { String(localized: $0.displayName) }.joined(separator: ", ")
        }
    }
}
