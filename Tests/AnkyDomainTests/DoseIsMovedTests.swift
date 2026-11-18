// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseIsMovedTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let minuteStart = Date(timeIntervalSince1970: 1_800_000_000)

    private func dose(at takenAt: Date, beforeReadingID: UUID? = nil) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt, beforeReadingID: beforeReadingID)
    }

    private func isMoved(
        _ saved: Dose, medicationID: UUID? = nil, at takenAt: Date? = nil, beforeReadingID: UUID? = nil
    ) -> Bool {
        saved.isMoved(
            to: medicationID ?? saved.medicationID,
            at: takenAt ?? saved.takenAt,
            beforeReadingID: beforeReadingID,
            calendar: calendar
        )
    }

    @Test func theSavedMedicationAndTimeIsNotMoved() {
        #expect(!isMoved(dose(at: minuteStart)))
    }

    @Test func anotherMedicationIsMoved() {
        #expect(isMoved(dose(at: minuteStart), medicationID: UUID()))
    }

    @Test func anotherMinuteIsMoved() {
        #expect(isMoved(dose(at: minuteStart), at: minuteStart.addingTimeInterval(60)))
    }

    @Test func anotherDayIsMoved() {
        #expect(isMoved(dose(at: minuteStart), at: minuteStart.addingTimeInterval(-86400)))
    }

    @Test func theSecondsTheDateWheelDropsAreNotMoved() {
        #expect(!isMoved(dose(at: minuteStart.addingTimeInterval(37)), at: minuteStart))
    }

    @Test func aTimeMovedAndPutBackIsNotMoved() {
        #expect(!isMoved(dose(at: minuteStart.addingTimeInterval(37)), at: minuteStart.addingTimeInterval(5)))
    }

    @Test func theSavedBeforeReadingIsNotMoved() {
        let saved = dose(at: minuteStart, beforeReadingID: UUID())

        #expect(!isMoved(saved, beforeReadingID: saved.beforeReadingID))
    }

    @Test func anotherBeforeReadingIsMoved() {
        #expect(isMoved(dose(at: minuteStart, beforeReadingID: UUID()), beforeReadingID: UUID()))
    }

    @Test func aBeforeReadingAddedToADoseWithNoneIsMoved() {
        #expect(isMoved(dose(at: minuteStart), beforeReadingID: UUID()))
    }

    @Test func aBeforeReadingClearedIsMoved() {
        #expect(isMoved(dose(at: minuteStart, beforeReadingID: UUID()), beforeReadingID: nil))
    }
}
