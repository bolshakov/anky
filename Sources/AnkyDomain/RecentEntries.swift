// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum RecentEntries {
    public static func distinct(from entries: [Entry], limit: Int) -> [RecentEntry] {
        guard limit > 0 else { return [] }
        var kept = KeptGroups(limit: limit)
        for position in entries.indices.reversed() {
            kept.offer(entries[position], rank: Rank(date: entries[position].date, position: position))
        }
        return kept.newestFirst
    }
}

/// Orders an entry by its date, then by its save position, so the later saved of two equal dates ranks higher.
private struct Rank: Equatable, Comparable {
    let date: Date
    let position: Int

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        (lhs.date, lhs.position) < (rhs.date, rhs.position)
    }
}

/// The `limit` groups whose newest entry ranks highest so far. A group's rank only rises as more of its entries are
/// offered, and it is evicted only when a higher-ranked group arrives, so an evicted group never needs its old rank.
private struct KeptGroups {
    private struct Group {
        var rank: Rank
        let recent: RecentEntry
    }

    let limit: Int
    private var groups: [Group] = []

    init(limit: Int) {
        self.limit = limit
    }

    mutating func offer(_ entry: Entry, rank: Rank) {
        if isFull, let weakest = weakestIndex, rank < groups[weakest].rank {
            return
        }
        let recent = RecentEntry(entry)
        if let index = groups.firstIndex(where: { $0.recent == recent }) {
            groups[index].rank = max(groups[index].rank, rank)
        } else if isFull, let weakest = weakestIndex {
            groups[weakest] = Group(rank: rank, recent: recent)
        } else {
            groups.append(Group(rank: rank, recent: recent))
        }
    }

    var newestFirst: [RecentEntry] {
        groups.sorted { $0.rank > $1.rank }.map(\.recent)
    }

    private var isFull: Bool {
        groups.count == limit
    }

    private var weakestIndex: Int? {
        groups.indices.min { groups[$0].rank < groups[$1].rank }
    }
}
