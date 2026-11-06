// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInReminderTapTests {
    private let takenAt = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333)
    private let medicationID = UUID()
    private var due: Date {
        takenAt.addingTimeInterval(30 * 60)
    }

    private func medication() -> Medication {
        Medication(id: medicationID, name: "Zorblex", takenAs: .asNeeded, createdAt: takenAt)
    }

    private func dose(delay: CheckInDelay? = .thirtyMinutes) -> Dose {
        var dose = Dose(id: UUID(), medicationID: medicationID, takenAt: takenAt)
        dose.checkInAfter = delay
        return dose
    }

    private func destination(
        of tapped: UUID,
        doses: [Dose],
        medications: [Medication]? = nil,
        at now: Date
    ) -> ReminderTapDestination {
        CheckInDue.destination(
            forReminderOf: tapped,
            doses: doses,
            medications: medications ?? [medication()],
            entries: [],
            now: now
        )
    }

    @Test func aTapOnTheReminderOfADoseWhoseWindowIsOpenOpensCheckInForThatDose() {
        let tapped = dose()
        #expect(destination(of: tapped.id, doses: [tapped], at: due.addingTimeInterval(60)) == .checkIn(tapped))
    }

    @Test func aTapOnTheReminderOfADoseWhoseWindowHasClosedOpensToday() {
        let tapped = dose()
        let closed = takenAt.addingTimeInterval(CheckInDue.windowLength)
        #expect(destination(of: tapped.id, doses: [tapped], at: closed) == .today)
    }

    @Test func aTapOnTheReminderOfADoseThatIsGoneOpensToday() {
        let other = dose()
        #expect(destination(of: UUID(), doses: [other], at: due.addingTimeInterval(60)) == .today)
    }

    @Test func theClockAtTheTapDecidesNotTheClockAtTheReminder() {
        let tapped = dose()
        let lastOpen = takenAt.addingTimeInterval(CheckInDue.windowLength - 1)
        #expect(destination(of: tapped.id, doses: [tapped], at: lastOpen) == .checkIn(tapped))
    }

    @Test func aTapOnADoseWhoseMedicationIsGoneOpensToday() {
        let tapped = dose()
        #expect(destination(of: tapped.id, doses: [tapped], medications: [], at: due.addingTimeInterval(60)) == .today)
    }

    @Test func aTapOnADoseThatANewerDoseClosedOpensToday() {
        let tapped = dose()
        var newer = Dose(id: UUID(), medicationID: medicationID, takenAt: takenAt.addingTimeInterval(20 * 60))
        newer.checkInAfter = nil
        #expect(destination(of: tapped.id, doses: [tapped, newer], at: due.addingTimeInterval(60)) == .today)
    }
}
