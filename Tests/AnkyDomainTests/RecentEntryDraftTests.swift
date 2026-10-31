// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct RecentEntryDraftTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let otherDate = Date(timeIntervalSince1970: 1_800_086_400)

    private func draft(_ places: [String] = [], kind: EntryKind = .stiffness, level: Int = 2) throws -> EntryDraft {
        var draft = try EntryDraft(severity: #require(Severity(level)), date: date)
        draft.kind = kind
        draft.places = places.map { PlaceID(rawValue: $0) }
        return draft
    }

    private func recent(_ places: [String], kind: EntryKind = .pain, level: Int = 4) throws -> RecentEntry {
        try RecentEntry(Entry(draft: draft(places, kind: kind, level: level)))
    }

    @Test func applyingARecentEntryCopiesKindLevelAndPlaces() throws {
        var target = try draft(["neck", "hip_l"], kind: .stiffness, level: 2)
        try target.apply(recent(["lower", "si_l"], kind: .pain, level: 4))
        #expect(target.kind == .pain)
        #expect(target.severity == Severity(4))
        #expect(target.places == ["lower", "si_l"].map { PlaceID(rawValue: $0) })
    }

    @Test func applyingARecentEntryKeepsTheDateAndTheNote() throws {
        var target = try draft(["neck"])
        target.note = "Walk note"
        try target.apply(recent(["lower"]))
        #expect(target.date == date)
        #expect(target.note == "Walk note")
    }

    @Test func applyingAFatigueEntryClearsThePlaces() throws {
        var target = try draft(["lower", "neck"], kind: .pain)
        try target.apply(recent([], kind: .fatigue, level: 6))
        #expect(target.kind == .fatigue)
        #expect(target.places.isEmpty)
    }

    @Test func aDraftFromARecentEntryHasTheGivenDateAndNoNote() throws {
        let chip = try recent(["lower", "si_l"], kind: .stiffness, level: 5)
        let made = chip.draft(at: otherDate)
        #expect(made.date == otherDate)
        #expect(made.note.isEmpty)
        #expect(made.kind == .stiffness)
        #expect(made.severity == Severity(5))
        #expect(made.places == chip.places)
    }
}
