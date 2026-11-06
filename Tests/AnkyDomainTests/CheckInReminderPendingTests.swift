// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CheckInReminderPendingTests {
    private let fireAt = Date(timeIntervalSinceReferenceDate: 60 * 13_333_333)
    private let doseID = UUID()

    private var wanted: CheckInReminder {
        CheckInReminder(doseID: doseID, fireAt: fireAt)
    }

    @Test func aReminderWithNoPendingRequestIsToBeScheduled() {
        #expect(CheckInReminder.toSchedule([wanted], pending: [:]) == [wanted])
    }

    /// A relaunch reconciles again, and the reminder must be delivered once, not twice.
    @Test func aReminderAlreadyPendingAtTheSameMomentIsLeftAlone() {
        #expect(CheckInReminder.toSchedule([wanted], pending: [doseID: fireAt]).isEmpty)
    }

    @Test func aReminderPendingAtAnotherMomentIsScheduledAgain() {
        let pending = [doseID: fireAt.addingTimeInterval(-60)]
        #expect(CheckInReminder.toSchedule([wanted], pending: pending) == [wanted])
    }

    @Test func aPendingRequestAWholeSecondOffIsScheduledAgain() {
        let pending = [doseID: fireAt.addingTimeInterval(1)]
        #expect(CheckInReminder.toSchedule([wanted], pending: pending) == [wanted])
    }

    @Test func aPendingRequestUnderASecondOffIsLeftAlone() {
        let pending = [doseID: fireAt.addingTimeInterval(0.4)]
        #expect(CheckInReminder.toSchedule([wanted], pending: pending).isEmpty)
    }

    @Test func aPendingRequestOfAnotherDoseDoesNotCoverTheReminder() {
        #expect(CheckInReminder.toSchedule([wanted], pending: [UUID(): fireAt]) == [wanted])
    }

    @Test func nothingWantedSchedulesNothing() {
        #expect(CheckInReminder.toSchedule([], pending: [doseID: fireAt]).isEmpty)
    }

    @Test func aPendingRequestWhoseDoseIsNoLongerWantedIsToBeCancelled() {
        #expect(CheckInReminder.toCancel(pending: [doseID], wanted: []) == [doseID])
    }

    @Test func aPendingRequestWhoseDoseIsStillWantedIsKept() {
        #expect(CheckInReminder.toCancel(pending: [doseID], wanted: [wanted]).isEmpty)
    }

    @Test func onlyTheRequestsOfDosesNoLongerWantedAreCancelled() {
        let closed = UUID()
        #expect(CheckInReminder.toCancel(pending: [closed, doseID], wanted: [wanted]) == [closed])
    }

    @Test func nothingPendingCancelsNothing() {
        #expect(CheckInReminder.toCancel(pending: [], wanted: []).isEmpty)
    }
}
