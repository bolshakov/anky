// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The BASDAI results a report may carry: those dated from the period's start to `now`, both ends included, newest
/// first in the order of the BASDAI list. `included(_:)` is the one place the Report screen's switch is applied.
public struct ReportBasdai: Equatable, Sendable {
    public let inPeriod: [BasdaiResult]

    public init(results: [BasdaiResult], period: ReportPeriod, now: Date, calendar: Calendar) {
        let range = period.start(endingAt: now, calendar: calendar) ... now
        inPeriod = results
            .filter { range.contains($0.date) }
            .sorted { ($0.date, $0.createdAt) > ($1.date, $1.createdAt) }
    }

    public func included(_ includes: Bool) -> [BasdaiResult] {
        includes ? inPeriod : []
    }
}
