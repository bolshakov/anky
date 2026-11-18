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

        let moved = original.moved(to: fennimax, at: later, beforeReadingID: original.beforeReadingID)

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

        let moved = original.moved(to: UUID(), at: date.addingTimeInterval(600), beforeReadingID: nil)

        #expect(moved.loggedAt == original.loggedAt)
    }

    @Test func aMoveWritesTheBeforeReadingItIsGiven() {
        let original = Dose(id: UUID(), medicationID: UUID(), takenAt: date, beforeReadingID: UUID())
        let linked = UUID()

        #expect(original.moved(to: original.medicationID, at: date, beforeReadingID: linked).beforeReadingID == linked)
    }

    @Test func aMoveWithNoBeforeReadingClearsIt() {
        let original = Dose(id: UUID(), medicationID: UUID(), takenAt: date, beforeReadingID: UUID())

        #expect(original.moved(to: original.medicationID, at: date, beforeReadingID: nil).beforeReadingID == nil)
    }

    @Test func aMoveWithAClearedAfterReadingStoresNil() {
        var original = Dose(id: UUID(), medicationID: UUID(), takenAt: date)
        original.afterReadingID = UUID()

        let moved = original.moved(
            to: original.medicationID,
            at: date,
            beforeReadingID: nil,
            afterReadingID: .some(nil)
        )

        #expect(moved.afterReadingID == nil)
    }

    @Test func aMoveWithNoAfterReadingArgumentKeepsTheStoredOne() {
        var original = Dose(id: UUID(), medicationID: UUID(), takenAt: date)
        original.afterReadingID = UUID()

        let moved = original.moved(to: UUID(), at: date.addingTimeInterval(600), beforeReadingID: nil)

        #expect(moved.afterReadingID == original.afterReadingID)
    }

    @Test func aMoveWritesTheAfterReadingItIsGiven() {
        let original = Dose(id: UUID(), medicationID: UUID(), takenAt: date)
        let linked = UUID()

        let moved = original.moved(to: original.medicationID, at: date, beforeReadingID: nil, afterReadingID: linked)

        #expect(moved.afterReadingID == linked)
    }
}
