// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DailyReminderTapTests {
    @Test func theFixedIdentifierIsATap() {
        #expect(DailyReminder.isTap(identifier: "daily-reminder"))
    }

    @Test func aDoseReminderIdentifierIsNotATap() {
        #expect(!DailyReminder.isTap(identifier: UUID().uuidString))
    }

    @Test func anEmptyIdentifierIsNotATap() {
        #expect(!DailyReminder.isTap(identifier: ""))
    }
}
