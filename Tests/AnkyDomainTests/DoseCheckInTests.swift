// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct DoseCheckInTests {
    @Test func aMedicationWithNoSavedDelayStartsOffAtTwoHours() {
        let start = DoseCheckIn(savedDelay: nil)
        #expect(!start.isOn)
        #expect(start.delay == .twoHours)
        #expect(start.checkInAfter == nil)
    }

    @Test(arguments: CheckInDelay.allCases)
    func aMedicationWithASavedDelayStartsOnAtThatDelay(_ delay: CheckInDelay) {
        let start = DoseCheckIn(savedDelay: delay)
        #expect(start.isOn)
        #expect(start.checkInAfter == delay)
    }

    @Test func turningOnWithNoSavedDelaySavesTwoHours() {
        var checkIn = DoseCheckIn(savedDelay: nil)
        checkIn.isOn = true
        #expect(checkIn.checkInAfter == .twoHours)
    }

    @Test func turningOffSavesNoDelay() {
        var checkIn = DoseCheckIn(savedDelay: .oneHour)
        checkIn.isOn = false
        #expect(checkIn.checkInAfter == nil)
    }

    @Test func aChangedDelaySavesTheDelayShown() {
        var checkIn = DoseCheckIn(savedDelay: .oneHour)
        checkIn.delay = .fourHours
        #expect(checkIn.checkInAfter == .fourHours)
    }
}
