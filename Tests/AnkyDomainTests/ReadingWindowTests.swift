// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReadingWindowTests {
    private let doseTime = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333 + 10)

    private func entry(_ kind: EntryKind = .pain, at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(4)), date: date, note: nil, places: [])
    }

    private func ago(_ seconds: TimeInterval) -> Date {
        doseTime.addingTimeInterval(-seconds)
    }

    @Test func aReadingTwoHoursBeforeCountsAndAMinuteOlderDoesNot() throws {
        let edge = try entry(at: ago(ReadingWindow.length))
        let older = try entry(at: ago(ReadingWindow.length + 60))
        #expect(ReadingWindow.entries(in: [older, edge], before: doseTime).map(\.id) == [edge.id])
    }

    @Test func aReadingAMinuteAfterTheDoseDoesNotCount() throws {
        let later = try entry(at: doseTime.addingTimeInterval(60))
        #expect(ReadingWindow.entries(in: [later], before: doseTime).isEmpty)
    }

    @Test func aReadingInTheDoseMinuteCountsWhateverTheSeconds() throws {
        let earlierSeconds = try entry(at: ago(10))
        let laterSeconds = try entry(at: doseTime.addingTimeInterval(49))
        let result = ReadingWindow.entries(in: [earlierSeconds, laterSeconds], before: doseTime)
        #expect(Set(result.map(\.id)) == [earlierSeconds.id, laterSeconds.id])
    }

    @Test func theNewestReadingComesFirst() throws {
        let hourAgo = try entry(at: ago(3600))
        let tenMinutesAgo = try entry(at: ago(600))
        let halfHourAgo = try entry(at: ago(1800))
        let result = ReadingWindow.entries(in: [hourAgo, tenMinutesAgo, halfHourAgo], before: doseTime)
        #expect(result.map(\.id) == [tenMinutesAgo.id, halfHourAgo.id, hourAgo.id])
    }

    @Test func aTieOnTheMinuteListsTheEarlierStoredSecond() throws {
        let firstStored = try entry(at: ago(600))
        let secondStored = try entry(at: ago(595))
        let result = ReadingWindow.entries(in: [firstStored, secondStored], before: doseTime)
        #expect(result.map(\.id) == [secondStored.id, firstStored.id])
    }

    @Test func painStiffnessAndFatigueAllCount() throws {
        let readings = try EntryKind.allCases.map { try entry($0, at: ago(600)) }
        let result = ReadingWindow.entries(in: readings, before: doseTime)
        #expect(Set(result.map(\.id)) == Set(readings.map(\.id)))
    }

    @Test func latestIsTheFirstInWindow() throws {
        let older = try entry(at: ago(3000))
        let newest = try entry(at: ago(600))
        #expect(ReadingWindow.latest(in: [older, newest], before: doseTime)?.id == newest.id)
    }

    @Test func latestIsNilWhenNoReadingIsInWindow() throws {
        let outside = try entry(at: ago(ReadingWindow.length + 60))
        #expect(ReadingWindow.latest(in: [outside], before: doseTime) == nil)
    }

    @Test func aManualPickStillInWindowIsKept() throws {
        let manual = try entry(at: ago(3000))
        let newer = try entry(at: ago(600))
        let picked = ReadingWindow.pick(manual.id, in: [manual, newer], before: doseTime)
        #expect(picked?.id == manual.id)
    }

    @Test func aManualPickOutsideTheWindowFallsBackToTheNewestInWindow() throws {
        let manual = try entry(at: ago(ReadingWindow.length + 600))
        let newer = try entry(at: ago(600))
        let picked = ReadingWindow.pick(manual.id, in: [manual, newer], before: doseTime)
        #expect(picked?.id == newer.id)
    }

    @Test func aManualPickForAnEntryThatIsGoneFallsBackToTheNewestInWindow() throws {
        let newer = try entry(at: ago(600))
        let picked = ReadingWindow.pick(UUID(), in: [newer], before: doseTime)
        #expect(picked?.id == newer.id)
    }

    @Test func noManualPickUsesTheNewestInWindow() throws {
        let newer = try entry(at: ago(600))
        #expect(ReadingWindow.pick(nil, in: [newer], before: doseTime)?.id == newer.id)
    }

    @Test func pickIsNilWhenNothingIsInWindow() {
        #expect(ReadingWindow.pick(nil, in: [], before: doseTime) == nil)
    }
}
