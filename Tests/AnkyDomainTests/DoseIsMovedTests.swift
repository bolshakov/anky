// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseIsMovedTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let minuteStart = Date(timeIntervalSince1970: 1_800_000_000)

    private func dose(at takenAt: Date) -> Dose {
        Dose(id: UUID(), medicationID: UUID(), takenAt: takenAt)
    }

    @Test func theSavedMedicationAndTimeIsNotMoved() {
        let saved = dose(at: minuteStart)

        #expect(!saved.isMoved(to: saved.medicationID, at: saved.takenAt, calendar: calendar))
    }

    @Test func anotherMedicationIsMoved() {
        let saved = dose(at: minuteStart)

        #expect(saved.isMoved(to: UUID(), at: saved.takenAt, calendar: calendar))
    }

    @Test func anotherMinuteIsMoved() {
        let saved = dose(at: minuteStart)

        #expect(saved.isMoved(to: saved.medicationID, at: minuteStart.addingTimeInterval(60), calendar: calendar))
    }

    @Test func anotherDayIsMoved() {
        let saved = dose(at: minuteStart)

        #expect(saved.isMoved(to: saved.medicationID, at: minuteStart.addingTimeInterval(-86400), calendar: calendar))
    }

    @Test func theSecondsTheDateWheelDropsAreNotMoved() {
        let saved = dose(at: minuteStart.addingTimeInterval(37))
        let wheelTime = minuteStart

        #expect(!saved.isMoved(to: saved.medicationID, at: wheelTime, calendar: calendar))
    }

    @Test func aTimeMovedAndPutBackIsNotMoved() {
        let saved = dose(at: minuteStart.addingTimeInterval(37))
        let putBack = minuteStart.addingTimeInterval(5)

        #expect(!saved.isMoved(to: saved.medicationID, at: putBack, calendar: calendar))
    }
}
