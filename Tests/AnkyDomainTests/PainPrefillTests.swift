// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PainPrefillTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(_ kind: EntryKind, severity: Int, secondsFromNow: TimeInterval) throws -> Entry {
        try Entry(
            id: UUID(),
            kind: kind,
            severity: #require(Severity(severity)),
            date: now.addingTimeInterval(secondsFromNow),
            note: nil,
            places: []
        )
    }

    @Test func noEntriesGiveNoPrefill() {
        #expect(PainPrefill.latest(in: [], notAfter: now) == nil)
    }

    @Test func theLatestPainEntryNotLaterThanNowWins() throws {
        let older = try entry(.pain, severity: 2, secondsFromNow: -3600)
        let newer = try entry(.pain, severity: 5, secondsFromNow: -60)
        #expect(PainPrefill.latest(in: [newer, older], notAfter: now) == newer)
    }

    @Test func aPainEntryOfAnyAgeCounts() throws {
        let yearsAgo = try entry(.pain, severity: 4, secondsFromNow: -3 * 365 * 86400)
        #expect(PainPrefill.latest(in: [yearsAgo], notAfter: now) == yearsAgo)
    }

    @Test func aPainEntryLaterThanNowNeverCounts() throws {
        let future = try entry(.pain, severity: 8, secondsFromNow: 60)
        let past = try entry(.pain, severity: 3, secondsFromNow: -60)
        #expect(PainPrefill.latest(in: [future, past], notAfter: now) == past)
        #expect(PainPrefill.latest(in: [future], notAfter: now) == nil)
    }

    @Test func aPainEntryExactlyAtNowCounts() throws {
        let atNow = try entry(.pain, severity: 6, secondsFromNow: 0)
        #expect(PainPrefill.latest(in: [atNow], notAfter: now) == atNow)
    }

    @Test func stiffnessAndFatigueEntriesNeverCount() throws {
        let stiffness = try entry(.stiffness, severity: 9, secondsFromNow: -60)
        let fatigue = try entry(.fatigue, severity: 7, secondsFromNow: -30)
        let pain = try entry(.pain, severity: 1, secondsFromNow: -3600)
        #expect(PainPrefill.latest(in: [stiffness, fatigue, pain], notAfter: now) == pain)
        #expect(PainPrefill.latest(in: [stiffness, fatigue], notAfter: now) == nil)
    }
}
