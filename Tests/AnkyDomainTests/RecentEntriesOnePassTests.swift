// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct RecentEntriesOnePassTests {
    private let newest = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(minute: Int, _ places: [String] = [], kind: EntryKind = .pain, level: Int = 4) -> Entry {
        Entry(
            id: UUID(),
            kind: kind,
            severity: Severity(level)!,
            date: newest.addingTimeInterval(TimeInterval(minute * 60)),
            note: nil,
            places: places.map { PlaceID(rawValue: $0) }
        )
    }

    @Test func aGroupSavedBeforeAnOlderEntryStillRanksByDate() {
        let entries = [entry(minute: 100, ["neck"]), entry(minute: 60, ["hip_l"]), entry(minute: 1, ["lower"])]
        let expected = [RecentEntry(entries[0]), RecentEntry(entries[1])]
        #expect(RecentEntries.distinct(from: entries, limit: 2) == expected)
    }

    @Test func oneGroupAcrossElevenThousandEntriesIsOneRecentEntry() {
        let entries = (0 ..< MadeUpLog.size).map { entry(minute: $0 * 60, ["lower"]) }
        #expect(RecentEntries.distinct(from: entries, limit: 3) == [RecentEntry(entries[MadeUpLog.size - 1])])
    }

    @Test func twoGroupsUnderALimitOfThreeAreBothReturnedNewestFirst() {
        let entries = [entry(minute: 1, ["lower"]), entry(minute: 2, ["neck"]), entry(minute: 3, ["lower"])]
        let expected = [RecentEntry(entries[2]), RecentEntry(entries[1])]
        #expect(RecentEntries.distinct(from: entries, limit: 3) == expected)
    }

    @Test func manyEntriesOnOneDateGiveTheLaterSavedOfEachGroup() {
        let entries = MadeUpLog.sharingOneDate(endingAt: newest)
        let oracle = SortedRecentEntries.distinct(from: entries, limit: 3)
        #expect(RecentEntries.distinct(from: entries, limit: 3) == oracle)
        #expect(RecentEntries.distinct(from: entries, limit: 1) == [RecentEntry(entries[MadeUpLog.size - 1])])
    }

    @Test func onePassMatchesTheSortedOracleOnAnySaveOrder() {
        let entries = MadeUpLog.entries(endingAt: newest)
        var generator = SplitMix(state: 1)
        let reversed = Array(entries.reversed())
        let rotated = Array(entries[4000...] + entries[..<4000])
        let shuffled = entries.shuffled(using: &generator)
        for order in [entries, reversed, rotated, shuffled] {
            #expect(
                RecentEntries.distinct(from: order, limit: 3) == SortedRecentEntries.distinct(from: order, limit: 3)
            )
        }
    }
}

/// A fixed-seed generator, so a shuffled save order is the same on every run.
private struct SplitMix: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
