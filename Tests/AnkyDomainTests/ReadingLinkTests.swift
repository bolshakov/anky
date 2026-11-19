// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReadingLinkTests {
    private let doseTime = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ kind: EntryKind = .pain, at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(4)), date: date, note: nil, places: [])
    }

    @Test func aLinkedEntryBeforeTheDoseIsKept() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-600))
        #expect(ReadingLink.kept(linked.id, in: [linked], at: doseTime) == linked.id)
    }

    @Test func aLinkedEntryMoreThanTwoHoursBeforeTheDoseIsKept() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 86400))
        #expect(ReadingLink.kept(linked.id, in: [linked], at: doseTime) == linked.id)
    }

    @Test func aLinkedEntryJustOverTwoHoursBeforeTheDoseIsKeptThoughTheWindowLosesIt() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 60))
        #expect(ReadingWindow.pick(linked.id, in: [linked], before: doseTime) == nil)
        #expect(ReadingLink.kept(linked.id, in: [linked], at: doseTime) == linked.id)
    }

    @Test func aLinkedEntrySecondsAfterTheDoseButInTheNextMinuteIsNotKept() throws {
        let doseAtEndOfMinute = doseTime.addingTimeInterval(59)
        let nextMinute = try entry(at: doseTime.addingTimeInterval(60))
        #expect(ReadingLink.kept(nextMinute.id, in: [nextMinute], at: doseAtEndOfMinute) == nil)
    }

    @Test func aLinkedEntryInTheDosesOwnMinuteIsKeptWhateverItsSeconds() throws {
        let minuteStart = Date(timeIntervalSince1970: 1_800_000_000)
        let early = try entry(at: minuteStart)
        let late = try entry(at: minuteStart.addingTimeInterval(59))
        #expect(ReadingLink.kept(early.id, in: [early, late], at: minuteStart.addingTimeInterval(30)) == early.id)
        #expect(ReadingLink.kept(late.id, in: [early, late], at: minuteStart.addingTimeInterval(30)) == late.id)
    }

    @Test func aLinkedEntryAMinuteAfterTheDoseIsNotKept() throws {
        let later = try entry(at: doseTime.addingTimeInterval(60))
        #expect(ReadingLink.kept(later.id, in: [later], at: doseTime) == nil)
    }

    @Test func aLinkedEntryAbsentFromTheLogIsNotKept() throws {
        let other = try entry(at: doseTime.addingTimeInterval(-60))
        #expect(ReadingLink.kept(UUID(), in: [other], at: doseTime) == nil)
    }

    @Test func aLinkedEntryDeletedFromTheLogIsNotKeptSoEditDoseHasNoLink() throws {
        let deleted = try entry(at: doseTime.addingTimeInterval(-60))
        #expect(ReadingLink.kept(deleted.id, in: [], at: doseTime) == nil)
    }

    @Test func noLinkIsKeptAsNil() throws {
        let other = try entry(at: doseTime.addingTimeInterval(-60))
        #expect(ReadingLink.kept(nil, in: [other], at: doseTime) == nil)
    }

    @Test func aTimeMovedBackPastTheLinkedEntryAndForwardAgainLinksItAgain() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-3600))
        let movedBack = doseTime.addingTimeInterval(-7200)
        #expect(ReadingLink.kept(linked.id, in: [linked], at: movedBack) == nil)
        #expect(ReadingLink.kept(linked.id, in: [linked], at: doseTime) == linked.id)
    }

    @Test func resolveReturnsTheLinkedEntryEvenWhenANewerOneIsInTheWindow() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 3600))
        let newer = try entry(at: doseTime.addingTimeInterval(-60))
        let resolved = ReadingLink.resolve(linked: linked.id, manual: nil, in: [linked, newer], at: doseTime)
        #expect(resolved?.id == linked.id)
    }

    @Test func resolveTakesTheLinkedEntryOverAManualPick() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-3600))
        let manual = try entry(at: doseTime.addingTimeInterval(-60))
        let resolved = ReadingLink.resolve(linked: linked.id, manual: manual.id, in: [linked, manual], at: doseTime)
        #expect(resolved?.id == linked.id)
    }

    @Test func resolveFallsBackToTheManualPickWhenTheLinkIsAfterTheDose() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(120))
        let manual = try entry(at: doseTime.addingTimeInterval(-3600))
        let newest = try entry(at: doseTime.addingTimeInterval(-60))
        let resolved = ReadingLink.resolve(
            linked: linked.id,
            manual: manual.id,
            in: [linked, manual, newest],
            at: doseTime
        )
        #expect(resolved?.id == manual.id)
    }

    @Test func resolveFallsBackToTheNewestInWindowWithNoLink() throws {
        let older = try entry(at: doseTime.addingTimeInterval(-3600))
        let newest = try entry(at: doseTime.addingTimeInterval(-60))
        let resolved = ReadingLink.resolve(linked: nil, manual: nil, in: [older, newest], at: doseTime)
        #expect(resolved?.id == newest.id)
    }

    @Test func resolveLeavesAManualPickOutsideTheWindowUnpicked() throws {
        let tooOld = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 60))
        #expect(ReadingLink.resolve(linked: nil, manual: tooOld.id, in: [tooOld], at: doseTime) == nil)
    }

    @Test func aTimeMovedBackPastTheLinkedEntryResolvesToTheWindowPickAndBackToTheLink() throws {
        let linked = try entry(at: doseTime.addingTimeInterval(-3600))
        let movedBack = doseTime.addingTimeInterval(-7200)
        #expect(ReadingLink.resolve(linked: linked.id, manual: nil, in: [linked], at: movedBack) == nil)
        #expect(ReadingLink.resolve(linked: linked.id, manual: nil, in: [linked], at: doseTime)?.id == linked.id)
    }

    private func ids(_ entries: [Entry]) -> [UUID] {
        entries.map(\.id)
    }

    @Test func choicesAreTheWindowEntriesWhenNothingIsChosen() throws {
        let inWindow = try entry(at: doseTime.addingTimeInterval(-600))
        let outside = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 60))
        let result = ReadingLink.choices(in: [outside, inWindow], chosen: nil, at: doseTime)
        #expect(ids(result) == [inWindow.id])
    }

    @Test func aChosenEntryOutsideTheWindowIsListedBelowTheWindowEntries() throws {
        let newer = try entry(at: doseTime.addingTimeInterval(-600))
        let older = try entry(at: doseTime.addingTimeInterval(-3600))
        let chosen = try entry(at: doseTime.addingTimeInterval(-3 * 3600))
        let result = ReadingLink.choices(in: [chosen, older, newer], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [newer.id, older.id, chosen.id])
    }

    @Test func aChosenEntryTooOldForTheWindowButNewerThanAnOlderOneSitsByDate() throws {
        let inWindow = try entry(at: doseTime.addingTimeInterval(-600))
        let chosen = try entry(at: doseTime.addingTimeInterval(-ReadingWindow.length - 60))
        let result = ReadingLink.choices(in: [inWindow, chosen], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [inWindow.id, chosen.id])
    }

    @Test func aChosenFatigueEntryInTheWindowIsListedInItsPlaceByDate() throws {
        let newer = try entry(at: doseTime.addingTimeInterval(-300))
        let chosen = try entry(.fatigue, at: doseTime.addingTimeInterval(-600))
        let older = try entry(.stiffness, at: doseTime.addingTimeInterval(-900))
        let result = ReadingLink.choices(in: [older, chosen, newer], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [newer.id, chosen.id, older.id])
    }

    @Test func aFatigueEntryThatIsNotChosenIsNotListed() throws {
        let chosen = try entry(at: doseTime.addingTimeInterval(-600))
        let fatigue = try entry(.fatigue, at: doseTime.addingTimeInterval(-300))
        let result = ReadingLink.choices(in: [chosen, fatigue], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [chosen.id])
    }

    @Test func aChosenEntryThatIsInTheWindowIsListedOnce() throws {
        let chosen = try entry(at: doseTime.addingTimeInterval(-600))
        let result = ReadingLink.choices(in: [chosen], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [chosen.id])
    }

    @Test func aChosenEntryAfterTheDoseIsNotListed() throws {
        let later = try entry(at: doseTime.addingTimeInterval(120))
        #expect(ReadingLink.choices(in: [later], chosen: later.id, at: doseTime).isEmpty)
    }

    @Test func aChosenEntryAbsentFromTheLogIsNotListed() throws {
        let inWindow = try entry(at: doseTime.addingTimeInterval(-600))
        let result = ReadingLink.choices(in: [inWindow], chosen: UUID(), at: doseTime)
        #expect(ids(result) == [inWindow.id])
    }

    @Test func aTieOnTheMinuteBetweenTheChosenAndAWindowEntryListsTheLaterStoredFirst() throws {
        let minute = Date(timeIntervalSince1970: 1_800_000_000 - 3600)
        let windowEntry = try entry(at: minute)
        let chosen = try entry(.fatigue, at: minute.addingTimeInterval(5))
        let result = ReadingLink.choices(in: [windowEntry, chosen], chosen: chosen.id, at: doseTime)
        #expect(ids(result) == [chosen.id, windowEntry.id])
    }
}
