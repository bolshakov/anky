// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct LogDoseChangeTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_030)
    private let zorblex = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: .distantPast)
    private let quibbanol = Medication(id: UUID(), name: "Quibbanol", takenAs: .asNeeded, createdAt: .distantPast)

    private func medication(_ base: Medication, checkInAfter: CheckInDelay?) -> Medication {
        var medication = base
        medication.checkInAfter = checkInAfter
        return medication
    }

    private func reading(minutesBack: Double) throws -> Entry {
        try Entry(
            id: UUID(), kind: .pain, severity: #require(Severity(4)), date: now.addingTimeInterval(-minutesBack * 60),
            note: nil, places: []
        )
    }

    private func untouched(preselected: UUID? = nil, active: [Medication]) -> LogDoseDraft {
        LogDoseDraft.untouched(preselected: preselected, active: active)
    }

    private func hasChanges(
        _ draft: LogDoseDraft, preselected: UUID? = nil, active: [Medication], entries: [Entry] = []
    ) -> Bool {
        draft.hasChanges(in: LogDoseContext(preselected: preselected, active: active, entries: entries, now: now))
    }

    @Test func anUntouchedFormHasNoChange() {
        let active = [zorblex, quibbanol]
        #expect(!hasChanges(untouched(active: active), active: active))
    }

    @Test func anUntouchedFormOpenedOnAMedicationHasNoChange() {
        let active = [zorblex, quibbanol]
        let draft = untouched(preselected: quibbanol.id, active: active)
        #expect(!hasChanges(draft, preselected: quibbanol.id, active: active))
    }

    @Test func anotherMedicationIsAChange() {
        let active = [zorblex, quibbanol]
        var draft = untouched(active: active)
        draft.selectedID = quibbanol.id
        #expect(hasChanges(draft, active: active))
    }

    @Test func aMedicationChosenAndChosenBackIsNoChange() {
        let active = [zorblex, quibbanol]
        var draft = untouched(active: active)
        draft.selectedID = quibbanol.id
        draft.selectedID = zorblex.id
        #expect(!hasChanges(draft, active: active))
    }

    @Test func aListThatReloadsUnderTheFormIsNoChange() {
        let before = [zorblex, quibbanol]
        let draft = untouched(preselected: quibbanol.id, active: before)
        let after = [zorblex]
        #expect(!hasChanges(draft, preselected: quibbanol.id, active: after))
    }

    @Test func aChosenMedicationThatLeavesTheListFallsBackWithoutAChange() {
        let before = [zorblex, quibbanol]
        var draft = untouched(active: before)
        draft.selectedID = quibbanol.id
        let after = [zorblex]
        #expect(!hasChanges(draft, active: after))
    }

    @Test func aTimeSetToTheClocksMinuteIsNoChange() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.takenAt = now.addingTimeInterval(-30)
        #expect(!hasChanges(draft, active: active))
    }

    @Test func aTimeSetAnHourBackIsAChange() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.takenAt = now.addingTimeInterval(-3600)
        #expect(hasChanges(draft, active: active))
    }

    @Test func aTimeSetOneMinuteBackIsAChange() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.takenAt = now.addingTimeInterval(-60)
        #expect(hasChanges(draft, active: active))
    }

    @Test func aTimeSetToTheClocksMinuteBecomesAChangeOnceTheClockMovesOn() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.takenAt = now
        let nextMinute = LogDoseContext(preselected: nil, active: active, entries: [], now: now.addingTimeInterval(60))
        #expect(draft.hasChanges(in: nextMinute))
    }

    @Test func anUntouchedFormStaysUnchangedWhenTheClockMovesOn() {
        let active = [zorblex]
        let draft = untouched(active: active)
        let later = LogDoseContext(preselected: nil, active: active, entries: [], now: now.addingTimeInterval(3600))
        #expect(!draft.hasChanges(in: later))
    }

    @Test func aReadingPickedByHandOverTheNewestIsAChange() throws {
        let older = try reading(minutesBack: 90)
        let newest = try reading(minutesBack: 10)
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.manualReadingID = older.id
        #expect(hasChanges(draft, active: active, entries: [older, newest]))
    }

    @Test func aReadingPickedByHandThatIsTheNewestAnywayIsNoChange() throws {
        let older = try reading(minutesBack: 90)
        let newest = try reading(minutesBack: 10)
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.manualReadingID = newest.id
        #expect(!hasChanges(draft, active: active, entries: [older, newest]))
    }

    @Test func aReadingLoggedFromLogDoseThatIsNotTheNewestIsAChange() throws {
        let newest = try reading(minutesBack: 10)
        let added = try reading(minutesBack: 60)
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.manualReadingID = added.id
        #expect(hasChanges(draft, active: active, entries: [added, newest]))
    }

    @Test func aReadingLoggedFromLogDoseThatBecomesTheNewestIsNoChange() throws {
        let existing = try reading(minutesBack: 90)
        let added = try reading(minutesBack: 0)
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.manualReadingID = added.id
        #expect(!hasChanges(draft, active: active, entries: [existing, added]))
    }

    @Test func aManualPickThatLeftTheWindowIsNoChange() throws {
        let newest = try reading(minutesBack: 10)
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.manualReadingID = UUID()
        #expect(!hasChanges(draft, active: active, entries: [newest]))
    }

    @Test func aCheckInSwitchedOnIsAChange() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.checkIn.isOn = true
        #expect(hasChanges(draft, active: active))
    }

    @Test func aCheckInDelayChangedWhileOnIsAChange() {
        let active = [medication(zorblex, checkInAfter: .oneHour)]
        var draft = untouched(active: active)
        draft.checkIn.delay = .fourHours
        #expect(hasChanges(draft, active: active))
    }

    @Test func aDelayPickedWhileTheSwitchIsOffIsNoChange() {
        let active = [zorblex]
        var draft = untouched(active: active)
        draft.checkIn.delay = .fourHours
        #expect(!hasChanges(draft, active: active))
    }

    @Test func aCheckInSwitchedOffAndBackOnIsNoChange() {
        let active = [medication(zorblex, checkInAfter: .oneHour)]
        var draft = untouched(active: active)
        draft.checkIn.isOn = false
        draft.checkIn.isOn = true
        #expect(!hasChanges(draft, active: active))
    }

    @Test func aDelayChangedAndSavedUnderManageIsNoChange() {
        let before = [medication(zorblex, checkInAfter: .oneHour)]
        var draft = untouched(active: before)
        let after = [medication(zorblex, checkInAfter: .fourHours)]
        draft.checkIn = draft.checkIn.following(savedDelay: .fourHours, from: .oneHour)
        #expect(!hasChanges(draft, active: after))
    }

    @Test func aDelayThePersonChangedStaysAChangeWhenManageSavesAnother() {
        let before = [medication(zorblex, checkInAfter: .oneHour)]
        var draft = untouched(active: before)
        draft.checkIn.delay = .twoHours
        let after = [medication(zorblex, checkInAfter: .fourHours)]
        draft.checkIn = draft.checkIn.following(savedDelay: .fourHours, from: .oneHour)
        #expect(hasChanges(draft, active: after))
    }

    @Test func aMedicationChosenWithItsOwnSavedCheckInAndChosenBackIsNoChange() {
        let active = [medication(zorblex, checkInAfter: nil), medication(quibbanol, checkInAfter: .oneHour)]
        var draft = untouched(active: active)
        draft.selectedID = quibbanol.id
        draft.checkIn = DoseCheckIn(savedDelay: .oneHour)
        draft.selectedID = zorblex.id
        draft.checkIn = DoseCheckIn(savedDelay: nil)
        #expect(!hasChanges(draft, active: active))
    }

    @Test func aFormWithNoMedicationsHasNoChange() {
        #expect(!hasChanges(untouched(active: []), active: []))
    }
}
