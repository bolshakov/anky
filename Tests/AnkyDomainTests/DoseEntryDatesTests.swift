// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseEntryDatesTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aPastDoseStartsAndStopsAtTheDoseTime() {
        let doseTime = now.addingTimeInterval(-86400)
        let dates = DoseEntryDates(doseAt: doseTime, now: now)
        #expect(dates.start == doseTime)
        #expect(dates.latest == doseTime)
    }

    @Test func aDoseLaterThanNowStartsAtNowAndStopsAtTheDoseTime() {
        let doseTime = now.addingTimeInterval(3600)
        let dates = DoseEntryDates(doseAt: doseTime, now: now)
        #expect(dates.start == now)
        #expect(dates.latest == doseTime)
    }

    @Test func aDoseAtNowStartsAndStopsAtNow() {
        let dates = DoseEntryDates(doseAt: now, now: now)
        #expect(dates.start == now)
        #expect(dates.latest == now)
    }
}
