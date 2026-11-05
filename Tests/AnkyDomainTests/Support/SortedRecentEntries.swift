// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

/// The sort-based grouping that the one-pass pass replaced. It is the oracle the one-pass pass must match on any save
/// order.
enum SortedRecentEntries {
    static func distinct(from entries: [Entry], limit: Int) -> [RecentEntry] {
        guard limit > 0 else { return [] }
        var seen = Set<RecentEntry>()
        let newestFirst = entries.enumerated()
            .sorted { ($0.element.date, $0.offset) > ($1.element.date, $1.offset) }
            .map { RecentEntry($0.element) }
        return Array(newestFirst.filter { seen.insert($0).inserted }.prefix(limit))
    }
}
