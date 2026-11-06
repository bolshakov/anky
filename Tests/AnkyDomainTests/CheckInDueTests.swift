// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInDueTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333)
    private let medicationID = UUID()

    private func medication(archived: Bool = false) -> Medication {
        var zorblex = Medication(id: medicationID, name: "Zorblex", takenAs: .asNeeded, createdAt: takenAt)
        zorblex.archivedAt = archived ? takenAt : nil
        return zorblex
    }

    private func dose(
        at time: Date? = nil,
        delay: CheckInDelay? = .thirtyMinutes,
        before: UUID? = nil,
        after: UUID? = nil,
        medicationID: UUID? = nil,
        loggedAt: Date? = nil
    ) -> Dose {
        var dose = Dose(
            id: UUID(),
            medicationID: medicationID ?? self.medicationID,
            takenAt: time ?? takenAt,
            beforeReadingID: before
        )
        dose.checkInAfter = delay
        dose.afterReadingID = after
        dose.loggedAt = loggedAt
        return dose
    }

    private func entry(id: UUID = UUID(), kind: EntryKind = .pain, at date: Date) throws -> Entry {
        try Entry(id: id, kind: kind, severity: #require(Severity(6)), date: date, note: nil, places: [])
    }

    /// Whether `target` is in the offer at `now`, given the other doses in the store.
    private func offered(
        _ target: Dose,
        alongside others: [Dose] = [],
        medications: [Medication]? = nil,
        entries: [Entry] = [],
        now: Date
    ) -> Bool {
        CheckInDue.waiting(
            doses: [target] + others,
            medications: medications ?? [medication()],
            entries: entries,
            now: now
        ).contains { $0.id == target.id }
    }

    @Test func aDoseIsOfferedFromTheMomentItsDelayHasPassed() {
        let due = takenAt.addingTimeInterval(30 * 60)
        #expect(offered(dose(), now: due))
        #expect(!offered(dose(), now: due.addingTimeInterval(-1)))
    }

    @Test func aDoseWithCheckInOffIsNeverOffered() {
        #expect(!offered(dose(delay: nil), now: takenAt.addingTimeInterval(24 * 60 * 60)))
    }

    @Test func aDoseWithNoMedicationIsNeverOffered() {
        #expect(!offered(dose(), medications: [], now: takenAt.addingTimeInterval(3600)))
    }

    @Test func aDoseOfAnArchivedMedicationIsOfferedInsideItsTwelveHours() {
        #expect(offered(dose(), medications: [medication(archived: true)], now: takenAt.addingTimeInterval(3600)))
    }

    @Test func aDoseWithItsAfterReadingIsNotOffered() throws {
        let reading = try entry(at: takenAt)
        #expect(!offered(dose(after: reading.id), entries: [reading], now: takenAt.addingTimeInterval(3600)))
    }

    /// The after-reading id points at an entry that was deleted, so the dose reads no after-reading and is offered
    /// again.
    @Test func aDoseWhoseAfterEntryWasDeletedIsOfferedAgain() {
        #expect(offered(dose(after: UUID()), now: takenAt.addingTimeInterval(3600)))
    }

    @Test func theDelayIsTheDosesOwnNotTheMedicationsSavedDelay() {
        var saved = medication()
        saved.checkInAfter = .fourHours
        #expect(offered(dose(delay: .thirtyMinutes), medications: [saved], now: takenAt.addingTimeInterval(30 * 60)))
    }

    @Test func theOfferListIsOldestFirst() {
        let later = dose(at: takenAt.addingTimeInterval(20))
        let earlier = dose(at: takenAt.addingTimeInterval(5))
        let result = CheckInDue.waiting(
            doses: [later, earlier],
            medications: [medication()],
            entries: [],
            now: takenAt.addingTimeInterval(3600)
        )
        #expect(result.map(\.id) == [earlier.id, later.id])
    }

    @Test func theOfferListIsEmptyWithNoMedicationForTheDose() {
        let result = CheckInDue.waiting(doses: [dose()], medications: [], entries: [],
                                        now: takenAt.addingTimeInterval(3600))
        #expect(result.isEmpty)
    }

    @Test func theWindowCloses12HoursAfterTheDoseTime() {
        let closing = takenAt.addingTimeInterval(12 * 60 * 60)
        #expect(offered(dose(), now: closing.addingTimeInterval(-1)))
        #expect(!offered(dose(), now: closing))
    }

    @Test func anOfferOpensToTheSecondWhenTheDoseTimeHasSeconds() {
        let taken = dose(at: takenAt.addingTimeInterval(20))
        let due = takenAt.addingTimeInterval(20 + 30 * 60)
        #expect(!offered(taken, now: due.addingTimeInterval(-1)))
        #expect(offered(taken, now: due))
    }

    @Test func anOfferClosesToTheSecondWhenTheDoseTimeHasSeconds() {
        let taken = dose(at: takenAt.addingTimeInterval(20))
        let closing = takenAt.addingTimeInterval(20 + 12 * 60 * 60)
        #expect(offered(taken, now: closing.addingTimeInterval(-1)))
        #expect(!offered(taken, now: closing))
    }

    @Test func aNewerDoseOfAnotherMedicationClosesTheDose() {
        let rival = Medication(id: UUID(), name: "Quellan", takenAs: .asNeeded, createdAt: takenAt)
        let newer = dose(at: takenAt.addingTimeInterval(600), medicationID: rival.id)
        #expect(!offered(
            dose(), alongside: [newer], medications: [medication(), rival], now: takenAt.addingTimeInterval(3600)
        ))
    }

    @Test func aNewerDoseWithCheckInOffClosesTheDose() {
        let newer = dose(at: takenAt.addingTimeInterval(600), delay: nil)
        #expect(!offered(dose(), alongside: [newer], now: takenAt.addingTimeInterval(3600)))
    }

    @Test func anOlderDoseDoesNotCloseTheDose() {
        let older = dose(at: takenAt.addingTimeInterval(-600))
        #expect(offered(dose(), alongside: [older], now: takenAt.addingTimeInterval(3600)))
    }

    /// Dose times compare by minute, so the dose logged last wins a tie whatever the seconds of each dose time.
    @Test func ofTwoDosesInOneMinuteTheOneLoggedLastIsTheNewer() {
        let takenLate = dose(at: takenAt.addingTimeInterval(50), loggedAt: takenAt.addingTimeInterval(1000))
        let takenEarly = dose(at: takenAt.addingTimeInterval(10), loggedAt: takenAt.addingTimeInterval(2000))
        let now = takenAt.addingTimeInterval(3600)
        #expect(offered(takenEarly, alongside: [takenLate], now: now))
        #expect(!offered(takenLate, alongside: [takenEarly], now: now))
    }

    @Test func ofTwoDosesInOneMinuteWithNoLoggedOrderNeitherIsNewer() {
        let first = dose(at: takenAt.addingTimeInterval(10))
        let second = dose(at: takenAt.addingTimeInterval(50))
        let now = takenAt.addingTimeInterval(3600)
        #expect(offered(first, alongside: [second], now: now))
        #expect(offered(second, alongside: [first], now: now))
    }

    @Test func aDoseLoggedWithAnOrderIsNewerThanALegacyDoseInTheSameMinute() {
        let legacy = dose(at: takenAt.addingTimeInterval(10))
        let logged = dose(at: takenAt.addingTimeInterval(50), loggedAt: takenAt.addingTimeInterval(1000))
        let now = takenAt.addingTimeInterval(3600)
        #expect(!offered(legacy, alongside: [logged], now: now))
        #expect(offered(logged, alongside: [legacy], now: now))
    }

    @Test func deletingTheNewerDoseReopensTheEarlierOne() {
        let newer = dose(at: takenAt.addingTimeInterval(600))
        let earlier = dose()
        let now = takenAt.addingTimeInterval(3600)
        #expect(!offered(earlier, alongside: [newer], now: now))
        #expect(offered(earlier, now: now))
    }

    @Test func movingTheNewerDoseBackReopensTheEarlierOne() {
        let earlier = dose()
        let moved = dose(at: takenAt.addingTimeInterval(600)).moved(
            to: medicationID, at: takenAt.addingTimeInterval(-600)
        )
        #expect(offered(earlier, alongside: [moved], now: takenAt.addingTimeInterval(3600)))
    }

    @Test func aDoseMovedPastTheNewerOneTakesItsPlaceAsTheNewer() {
        let earlier = dose()
        let newer = dose(at: takenAt.addingTimeInterval(600))
        let moved = earlier.moved(to: medicationID, at: takenAt.addingTimeInterval(1200))
        let now = takenAt.addingTimeInterval(3600)
        #expect(offered(moved, alongside: [newer], now: now))
        #expect(!offered(newer, alongside: [moved], now: now))
    }

    @Test func aDoseTakenLaterIsNewerThanAnEarlierOneLoggedAfterIt() {
        let earlierTaken = dose(at: takenAt.addingTimeInterval(60), loggedAt: takenAt.addingTimeInterval(2000))
        let laterTaken = dose(at: takenAt.addingTimeInterval(5 * 60), loggedAt: takenAt.addingTimeInterval(1000))
        let now = takenAt.addingTimeInterval(3600)
        #expect(offered(laterTaken, alongside: [earlierTaken], now: now))
        #expect(!offered(earlierTaken, alongside: [laterTaken], now: now))
    }

    @Test func aDoseMovedEarlierIsNotNewerThanALaterOneLoggedBeforeIt() {
        let moved = dose(at: takenAt.addingTimeInterval(10 * 60), loggedAt: takenAt.addingTimeInterval(2000))
            .moved(to: medicationID, at: takenAt.addingTimeInterval(60))
        let laterTaken = dose(at: takenAt.addingTimeInterval(5 * 60), loggedAt: takenAt.addingTimeInterval(1000))
        let now = takenAt.addingTimeInterval(3600)
        #expect(offered(laterTaken, alongside: [moved], now: now))
        #expect(!offered(moved, alongside: [laterTaken], now: now))
    }

    @Test func aPainStiffnessOrFatigueEntryAtTheDueMomentClosesTheDose() throws {
        let due = takenAt.addingTimeInterval(30 * 60)
        let closing = try entry(at: due)
        #expect(!offered(dose(), entries: [closing], now: due.addingTimeInterval(600)))
    }

    @Test func anEntryOfAnyKindAfterTheDueMomentClosesTheDose() throws {
        let due = takenAt.addingTimeInterval(30 * 60)
        for kind in EntryKind.allCases {
            let closing = try entry(kind: kind, at: due.addingTimeInterval(10 * 60))
            #expect(!offered(dose(), entries: [closing], now: due.addingTimeInterval(20 * 60)), "\(kind)")
        }
    }

    /// The due moment is 30 minutes and 20 seconds, so an entry at 30 minutes and 5 seconds shares its minute.
    @Test func anEntryInTheDueMinuteBeforeTheDueSecondClosesTheDose() throws {
        let due = takenAt.addingTimeInterval(20 + 30 * 60)
        let closing = try entry(at: takenAt.addingTimeInterval(5 + 30 * 60))
        let taken = dose(at: takenAt.addingTimeInterval(20))
        #expect(!offered(taken, entries: [closing], now: due.addingTimeInterval(600)))
    }

    @Test func anEntryInTheMinuteBeforeTheDueMinuteChangesNothing() throws {
        let due = takenAt.addingTimeInterval(30 * 60)
        let before = try entry(at: due.addingTimeInterval(-60))
        #expect(offered(dose(), entries: [before], now: due.addingTimeInterval(600)))
    }

    @Test func theNextChangeIsTheEarliestDueMomentStillAhead() {
        let soon = dose(at: takenAt, delay: .thirtyMinutes)
        let later = dose(at: takenAt.addingTimeInterval(600), delay: .oneHour)
        let now = takenAt.addingTimeInterval(10 * 60)
        let next = CheckInDue.nextChange(doses: [later, soon], medications: [medication()], entries: [], after: now)
        #expect(next == takenAt.addingTimeInterval(30 * 60))
    }

    @Test func theNextChangeSkipsMomentsThatHavePassed() {
        let passed = dose(at: takenAt, delay: .thirtyMinutes)
        let ahead = dose(at: takenAt, delay: .fourHours)
        let now = takenAt.addingTimeInterval(60 * 60)
        let next = CheckInDue.nextChange(doses: [passed, ahead], medications: [medication()], entries: [], after: now)
        #expect(next == takenAt.addingTimeInterval(4 * 60 * 60))
    }

    @Test func theNextChangeIsTheEndOfTheWindowOnceTheDueMomentHasPassed() {
        let now = takenAt.addingTimeInterval(60 * 60)
        let next = CheckInDue.nextChange(doses: [dose()], medications: [medication()], entries: [], after: now)
        #expect(next == takenAt.addingTimeInterval(CheckInDue.windowLength))
    }

    @Test func theNextChangeIsNilOnceTheWindowHasClosed() {
        let now = takenAt.addingTimeInterval(CheckInDue.windowLength)
        let next = CheckInDue.nextChange(doses: [dose()], medications: [medication()], entries: [], after: now)
        #expect(next == nil)
    }

    @Test func theNextChangeIsNilWhenNoDoseWillWait() {
        let next = CheckInDue.nextChange(
            doses: [dose(delay: nil)],
            medications: [medication()],
            entries: [],
            after: takenAt
        )
        #expect(next == nil)
    }
}
