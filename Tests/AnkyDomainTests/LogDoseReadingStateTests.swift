// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct LogDoseReadingStateTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_030)
    private let asNeeded = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: .distantPast)
    private let scheduled = Medication(id: UUID(), name: "Quibbanol", takenAs: .scheduled, createdAt: .distantPast)

    private func remembering(_ base: Medication, _ memory: ReadingMemory) -> Medication {
        var medication = base
        medication.readingMemory = memory
        return medication
    }

    private func entry(minutesBack: Double) throws -> Entry {
        try Entry(
            id: UUID(), kind: .pain, severity: #require(Severity(4)), date: now.addingTimeInterval(-minutesBack * 60),
            note: nil, places: []
        )
    }

    private func context(
        preselected: UUID? = nil, active: [Medication], entries: [Entry] = []
    ) -> LogDoseContext {
        LogDoseContext(preselected: preselected, active: active, entries: entries, now: now)
    }

    private func untouched(preselected: UUID? = nil, active: [Medication]) -> LogDoseDraft {
        LogDoseDraft.untouched(preselected: preselected, active: active)
    }

    private func resolved(_ draft: LogDoseDraft, in context: LogDoseContext) -> UUID? {
        ReadingLink.resolve(
            linked: draft.linkedReadingID, manual: draft.manualReadingID, noReading: draft.noReading,
            in: context.entries, at: draft.takenAt ?? context.now
        )?.id
    }

    // MARK: resolve and Dose.logged

    @Test func noReadingResolvesToNoEntryWhateverElseIsSet() throws {
        let linked = try entry(minutesBack: 30)
        let manual = try entry(minutesBack: 10)
        let resolved = ReadingLink.resolve(
            linked: linked.id, manual: manual.id, noReading: true, in: [linked, manual], at: now
        )
        #expect(resolved == nil)
    }

    @Test func noReadingResolvesToNoEntryWithNothingPicked() throws {
        let newest = try entry(minutesBack: 10)
        #expect(ReadingLink.resolve(linked: nil, manual: nil, noReading: true, in: [newest], at: now) == nil)
    }

    @Test func noReadingFalseResolvesAsBefore() throws {
        let newest = try entry(minutesBack: 10)
        let resolved = ReadingLink.resolve(linked: nil, manual: nil, noReading: false, in: [newest], at: now)
        #expect(resolved?.id == newest.id)
    }

    @Test func aDoseLoggedWithNoReadingStoresNoBeforeReading() throws {
        let linked = try entry(minutesBack: 30)
        let newest = try entry(minutesBack: 10)
        let dose = Dose.logged(
            id: UUID(), medication: asNeeded, takenAt: now, entries: [linked, newest], manualReadingID: newest.id,
            linkedReadingID: linked.id, noReading: true, loggedAt: now
        )
        #expect(dose.beforeReadingID == nil)
    }

    // MARK: untouched and hasChanges

    @Test func anUntouchedFormIsNeitherNoReadingNorTouched() {
        let draft = untouched(active: [asNeeded])
        #expect(!draft.noReading)
        #expect(!draft.readingTouched)
    }

    @Test func anUntouchedFormOnAScheduledMedicationStartsAtNone() {
        #expect(untouched(preselected: scheduled.id, active: [asNeeded, scheduled]).noReading)
    }

    @Test func anUntouchedFormOnAMedicationRememberedAsNoneStartsAtNone() {
        let active = [remembering(asNeeded, .none)]
        #expect(untouched(active: active).noReading)
    }

    @Test func anUntouchedFormOnAScheduledMedicationRememberedAsEntryStartsAutomatic() {
        let active = [remembering(scheduled, .entry)]
        #expect(!untouched(active: active).noReading)
    }

    @Test func anUntouchedFormStartsFromTheFirstMedicationWhenNoneIsPreselected() {
        #expect(untouched(active: [scheduled, asNeeded]).noReading)
    }

    @Test func aFormThatStartsAtNoneForAScheduledMedicationHasNoChange() {
        let active = [scheduled]
        let draft = untouched(preselected: scheduled.id, active: active)
        #expect(!draft.hasChanges(in: context(preselected: scheduled.id, active: active)))
    }

    @Test func noneChosenOnAnAsNeededMedicationWithNoEntriesIsAChange() {
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.noReading = true
        #expect(draft.hasChanges(in: context(active: active)))
    }

    @Test func anEntryPickedOnAScheduledMedicationStartingAtNoneIsAChange() throws {
        let newest = try entry(minutesBack: 10)
        let active = [scheduled]
        var draft = untouched(preselected: scheduled.id, active: active)
        draft.noReading = false
        draft.manualReadingID = newest.id
        #expect(draft.hasChanges(in: context(preselected: scheduled.id, active: active, entries: [newest])))
    }

    @Test func noneChosenBackToTheAutomaticPickIsNoChange() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.noReading = true
        draft.noReading = false
        #expect(!draft.hasChanges(in: context(active: active, entries: [newest])))
    }

    // MARK: changingMedication

    @Test func changingToAScheduledMedicationOnAnUntouchedRowStartsAtNone() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded, scheduled]
        let draft = untouched(active: active).changingMedication(
            to: scheduled.id, in: context(active: active, entries: [newest])
        )
        #expect(draft.selectedID == scheduled.id)
        #expect(draft.noReading)
    }

    @Test func changingBackToAnAsNeededMedicationOnAnUntouchedRowStartsAutomatic() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded, scheduled]
        let context = context(active: active, entries: [newest])
        let draft = untouched(active: active)
            .changingMedication(to: scheduled.id, in: context)
            .changingMedication(to: asNeeded.id, in: context)
        #expect(!draft.noReading)
        #expect(resolved(draft, in: context) == newest.id)
    }

    @Test func changingMedicationOnAnUntouchedRowAppliesTheNewMedicationsRememberedNone() {
        let remembered = remembering(asNeeded, .none)
        let active = [scheduled, remembered]
        let draft = untouched(active: active).changingMedication(to: remembered.id, in: context(active: active))
        #expect(draft.noReading)
    }

    @Test func changingMedicationOnAnUntouchedRowClearsLeftoverPicks() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded, scheduled]
        var draft = untouched(active: active)
        draft.manualReadingID = newest.id
        draft.linkedReadingID = newest.id
        draft = draft.changingMedication(to: asNeeded.id, in: context(active: active, entries: [newest]))
        #expect(draft.manualReadingID == nil)
        #expect(draft.linkedReadingID == nil)
    }

    @Test func aTouchedRowKeepsItsEntryWhenTheMedicationChanges() throws {
        let picked = try entry(minutesBack: 40)
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded, scheduled]
        var draft = untouched(active: active)
        draft.manualReadingID = picked.id
        draft.readingTouched = true
        draft = draft.changingMedication(to: scheduled.id, in: context(active: active, entries: [picked, newest]))
        #expect(draft.selectedID == scheduled.id)
        #expect(draft.manualReadingID == picked.id)
        #expect(!draft.noReading)
        #expect(draft.readingTouched)
    }

    @Test func aTouchedRowKeepsNoneWhenTheMedicationChangesToAsNeeded() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded, scheduled]
        var draft = untouched(active: active)
        draft.noReading = true
        draft.readingTouched = true
        draft = draft.changingMedication(to: asNeeded.id, in: context(active: active, entries: [newest]))
        #expect(draft.noReading)
        #expect(resolved(draft, in: context(active: active, entries: [newest])) == nil)
    }

    @Test func changingMedicationWritesNoMemory() {
        let active = [asNeeded, scheduled]
        let draft = untouched(active: active).changingMedication(to: scheduled.id, in: context(active: active))
        #expect(active == [asNeeded, scheduled])
        #expect(draft.selectedID == scheduled.id)
    }

    @Test func changingToNoMedicationStartsAutomaticOnAnUntouchedRow() {
        let active = [scheduled]
        let draft = untouched(active: active).changingMedication(to: nil, in: context(active: active))
        #expect(draft.selectedID == nil)
        #expect(draft.noReading)
    }

    // MARK: movingTime

    @Test func aDoseTimeMovedWhileNoneIsChosenKeepsNone() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.noReading = true
        draft.readingTouched = true
        let context = context(active: active, entries: [newest])
        let later = draft.movingTime(to: now.addingTimeInterval(60), in: context)
        let earlier = draft.movingTime(to: now.addingTimeInterval(-3600), in: context)
        #expect(later.noReading)
        #expect(earlier.noReading)
        #expect(resolved(later, in: context) == nil)
        #expect(resolved(earlier, in: context) == nil)
    }
}
