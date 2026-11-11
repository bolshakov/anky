// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReminderTapKindTests {
    private let id = UUID(uuidString: "0A1B2C3D-4E5F-6789-ABCD-EF0123456789")!

    @Test func theFixedIdentifierIsTheDailyReminder() {
        #expect(ReminderTapKind.of(identifier: "daily-reminder") == .dailyReminder)
    }

    @Test func aBareUUIDIsACheckIn() {
        #expect(ReminderTapKind.of(identifier: id.uuidString) == .checkIn(id))
    }

    @Test func aDoseIdentifierIsDoseDueForItsMedication() {
        let identifier = DoseNotification(
            medicationID: id,
            medicationName: "A",
            fireAt: Date(timeIntervalSince1970: 1_900_000_000)
        ).identifier
        #expect(ReminderTapKind.of(identifier: identifier) == .doseDue(id))
    }

    @Test func aLowerCaseDoseIdentifierIsDoseDue() {
        let identifier = "dose-due.\(id.uuidString.lowercased()).1900000000"
        #expect(ReminderTapKind.of(identifier: identifier) == .doseDue(id))
    }

    @Test func anUpperCaseDoseIdentifierIsDoseDue() {
        let identifier = "dose-due.\(id.uuidString.uppercased()).1900000000"
        #expect(ReminderTapKind.of(identifier: identifier) == .doseDue(id))
    }

    @Test func aDoseIdentifierWithAMalformedTimeIsOther() {
        #expect(ReminderTapKind.of(identifier: "dose-due.\(id.uuidString).soon") == .other)
    }

    @Test func aDoseIdentifierWithoutAValidMedicationIsOther() {
        #expect(ReminderTapKind.of(identifier: "dose-due.not-a-uuid.1900000000") == .other)
    }

    @Test func anEmptyIdentifierIsOther() {
        #expect(ReminderTapKind.of(identifier: "") == .other)
    }

    @Test func anyOtherIdentifierIsOther() {
        #expect(ReminderTapKind.of(identifier: "something-else") == .other)
    }
}
