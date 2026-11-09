// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

@Suite(.serialized)
@MainActor
struct TenYearsOfEntriesTests {
    private struct Launch {
        let elapsed: Duration
        let count: Int
    }

    private struct ScratchFailure: Error {}

    private let newest = Date(timeIntervalSince1970: 1_800_000_000)
    private let ceiling = Duration.seconds(1)
    private let recentCeiling = Duration.milliseconds(50)

    /// The median of this many opens is what `distinct` checks against its ceiling.
    private let opens = 3

    /// The launch ceiling is on the fastest of this many opens, since a busy runner only adds time to some of them
    /// while a real slowdown adds it to all of them.
    private let launchOpens = 5

    /// What `distinct` returns on `MadeUpLog`, written by hand from its tail: newest date first, one entry per group.
    private var pinned: [RecentEntry] {
        [recent(.pain, 9, ["hip_l"]), recent(.fatigue, 8, []), recent(.pain, 6, ["si_r"])]
    }

    @Test func launchLoadOfTenYearsStaysUnderTheCeiling() throws {
        try withScratchFolder { folder in
            let url = folder.appending(path: "entries.store")
            try fill(url)
            checkLaunch((0 ..< launchOpens).map { _ in timedLaunch(url) })
        }
    }

    @Test func distinctOfTenYearsStaysUnderTheCeiling() {
        let entries = MadeUpLog.entries(endingAt: newest)
        let timings = (0 ..< opens).map { _ in
            ContinuousClock().measure { _ = RecentEntries.distinct(from: entries, limit: 3) }
        }
        #expect(timings.sorted()[opens / 2] < recentCeiling)
    }

    @Test func aLaunchThatHoldsTooFewEntriesFailsEvenWhenFast() {
        withKnownIssue {
            checkLaunch([Launch(elapsed: .milliseconds(10), count: 0)])
        } matching: { issue in
            issue.description.contains("11000")
        }
    }

    @Test func aSlowLaunchReportsDurationsAndCountsOnly() {
        withKnownIssue {
            checkLaunch([Launch(elapsed: .seconds(2), count: MadeUpLog.size)])
        } matching: { issue in
            let entryWords = ["pain", "stiffness", "fatigue", "lower", "neck", "hip_l", "si_r"]
            return issue.description.contains("2.0 seconds")
                && !entryWords.contains { issue.description.contains($0) }
        }
    }

    @Test func distinctPinsTheGroupsNewestByDate() {
        let entries = MadeUpLog.entries(endingAt: newest)
        let matches = RecentEntries.distinct(from: entries, limit: 3) == pinned
        #expect(matches)
    }

    @Test func thePinnedResultIsNotTheLastThreeGroupsSaved() {
        let entries = MadeUpLog.entries(endingAt: newest)
        let lastThree = entries.suffix(3).reversed().map(RecentEntry.init)
        let differs = lastThree != pinned
        #expect(differs)
    }

    @Test func theScratchFolderIsRemovedWhenTheBodyReturns() throws {
        var folder: URL?
        try withScratchFolder { folder = $0 }
        let path = try #require(folder?.path)
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test func theScratchFolderIsRemovedWhenTheBodyThrows() throws {
        var folder: URL?
        #expect(throws: ScratchFailure.self) {
            try withScratchFolder {
                folder = $0
                throw ScratchFailure()
            }
        }
        let path = try #require(folder?.path)
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    /// Takes durations and counts only, so no failure of the ceiling or the count can print an entry.
    private func checkLaunch(_ launches: [Launch]) {
        #expect(launches.map(\.count) == Array(repeating: MadeUpLog.size, count: launches.count))
        let fastest = launches.map(\.elapsed).min() ?? .zero
        #expect(fastest < ceiling)
    }

    private func timedLaunch(_ url: URL) -> Launch {
        var log: EntryLog?
        let elapsed = ContinuousClock().measure {
            log = EntryLog(store: DeferredEntryStore { try SwiftDataEntryStore(url: url) })
        }
        return Launch(elapsed: elapsed, count: log?.entries.count ?? 0)
    }

    /// Fills the store in its own scope, so its container is released before a launch is timed.
    private func fill(_ url: URL) throws {
        let container = try ModelContainer(for: EntryRecord.self, configurations: ModelConfiguration(url: url))
        let context = ModelContext(container)
        for (position, entry) in MadeUpLog.entries(endingAt: newest).enumerated() {
            context.insert(EntryRecord(entry, position: position))
        }
        try context.save()
    }

    private func withScratchFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func recent(_ kind: EntryKind, _ level: Int, _ places: [String]) -> RecentEntry {
        RecentEntry(Entry(
            id: UUID(),
            kind: kind,
            severity: Severity(level)!,
            date: newest,
            note: nil,
            places: places.map { PlaceID(rawValue: $0) }
        ))
    }
}
