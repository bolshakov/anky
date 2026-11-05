// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseMovedTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aMoveKeepsTheDosesOwnDelayAndBothReadings() {
        var original = Dose(id: UUID(), medicationID: UUID(), takenAt: date, beforeReadingID: UUID())
        original.checkInAfter = .twoHours
        original.afterReadingID = UUID()
        let fennimax = UUID()
        let later = date.addingTimeInterval(600)

        let moved = original.moved(to: fennimax, at: later)

        #expect(moved.id == original.id)
        #expect(moved.medicationID == fennimax)
        #expect(moved.takenAt == later)
        #expect(moved.checkInAfter == .twoHours)
        #expect(moved.beforeReadingID == original.beforeReadingID)
        #expect(moved.afterReadingID == original.afterReadingID)
    }

    @Test func aMoveKeepsTheMomentItWasLogged() {
        var original = Dose(id: UUID(), medicationID: UUID(), takenAt: date)
        original.loggedAt = date.addingTimeInterval(5)

        let moved = original.moved(to: UUID(), at: date.addingTimeInterval(600))

        #expect(moved.loggedAt == original.loggedAt)
    }
}
