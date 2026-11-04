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

    @Test(arguments: savedDelays, savedDelays)
    func anUntouchedCheckInFollowsTheNewSavedDelay(from oldDelay: CheckInDelay?, to newDelay: CheckInDelay?) {
        let checkIn = DoseCheckIn(savedDelay: oldDelay)
        #expect(checkIn.following(savedDelay: newDelay, from: oldDelay) == DoseCheckIn(savedDelay: newDelay))
    }

    @Test func aCheckInChangedOnTheScreenIsReturnedUnchanged() {
        var checkIn = DoseCheckIn(savedDelay: .oneHour)
        checkIn.delay = .fourHours
        #expect(checkIn.following(savedDelay: .threeHours, from: .oneHour) == checkIn)
    }

    @Test func aSwitchTurnedOffOnTheScreenStaysOffWhenTheSavedDelayChanges() {
        var checkIn = DoseCheckIn(savedDelay: .twoHours)
        checkIn.isOn = false
        #expect(!checkIn.following(savedDelay: .fourHours, from: .twoHours).isOn)
    }

    @Test(arguments: savedDelays, savedDelays)
    func aCheckInRebuiltForAnotherMedicationKeepsItsOwnDelay(from oldDelay: CheckInDelay?, to newDelay: CheckInDelay?) {
        let rebuilt = DoseCheckIn(savedDelay: newDelay)
        #expect(rebuilt.following(savedDelay: newDelay, from: oldDelay) == rebuilt)
    }

    private static let savedDelays: [CheckInDelay?] = [nil] + CheckInDelay.allCases.map { Optional($0) }
}
