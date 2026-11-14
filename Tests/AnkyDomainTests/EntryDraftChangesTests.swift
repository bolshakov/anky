// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EntryDraftChangesTests {
    private static let minute = Date(timeIntervalSince1970: 1_800_000_000)
    private let calendar = Calendar(identifier: .gregorian)

    private func draft(date: Date = minute) throws -> EntryDraft {
        try EntryDraft(severity: #require(Severity(4)), date: date)
    }

    @Test func anUntouchedDraftHasNoChange() throws {
        let start = try draft()
        #expect(!start.hasChanges(since: start, calendar: calendar))
    }

    @Test func aSeverityChangeIsAChange() throws {
        let start = try draft()
        var changed = start
        changed.severity = try #require(Severity(5))
        #expect(changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func aSeverityMovedAndPutBackIsNoChange() throws {
        let start = try draft()
        var changed = start
        changed.severity = try #require(Severity(9))
        changed.severity = start.severity
        #expect(!changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func aKindChangeIsAChange() throws {
        let start = try draft()
        var changed = start
        changed.kind = .stiffness
        #expect(changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func aNoteChangeIsAChange() throws {
        let start = try draft()
        var changed = start
        changed.note = "Walk note"
        #expect(changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func aPlaceToggledOnAndOffIsNoChange() throws {
        let start = try draft()
        let place = try #require(PlaceCatalog.allPlaces.first)
        var changed = start
        changed.togglePlace(place)
        #expect(changed.hasChanges(since: start, calendar: calendar))
        changed.togglePlace(place)
        #expect(!changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func aTimeMovedAMinuteIsAChange() throws {
        let start = try draft()
        let changed = try draft(date: Self.minute.addingTimeInterval(60))
        #expect(changed.hasChanges(since: start, calendar: calendar))
    }

    @Test func secondsInsideTheSameMinuteAreNoChange() throws {
        let opened = try #require(calendar.dateInterval(of: .minute, for: Self.minute)).start
        let start = try draft(date: opened.addingTimeInterval(41))
        let wheel = try draft(date: opened)
        #expect(!wheel.hasChanges(since: start, calendar: calendar))
    }
}
