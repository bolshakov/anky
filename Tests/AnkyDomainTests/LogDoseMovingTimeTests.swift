// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct LogDoseMovingTimeTests {
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

    @Test func movingTimeSetsTheTime() {
        let active = [asNeeded]
        let moved = now.addingTimeInterval(-3600)
        let draft = untouched(active: active).movingTime(to: moved, in: context(active: active))
        #expect(draft.takenAt == moved)
    }

    @Test func movingTimeToNilFollowsTheClockAgain() {
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.takenAt = now.addingTimeInterval(-3600)
        #expect(draft.movingTime(to: nil, in: context(active: active)).takenAt == nil)
    }

    @Test func aDoseTimeMovedWhileNoneIsChosenKeepsNoneOnAScheduledStart() {
        let active = [scheduled]
        let draft = untouched(preselected: scheduled.id, active: active)
        let moved = draft.movingTime(
            to: now.addingTimeInterval(-600),
            in: context(preselected: scheduled.id, active: active)
        )
        #expect(moved.noReading)
    }

    @Test func aLinkNoLongerKeptFallsBackToNoneForAScheduledMedication() throws {
        let linked = try entry(minutesBack: 40)
        let active = [scheduled]
        var draft = untouched(preselected: scheduled.id, active: active)
        draft.noReading = false
        draft.linkedReadingID = linked.id
        draft.readingTouched = true
        let context = context(preselected: scheduled.id, active: active, entries: [linked])
        let moved = draft.movingTime(to: now.addingTimeInterval(-45 * 60), in: context)
        #expect(moved.linkedReadingID == nil)
        #expect(moved.noReading)
        #expect(resolved(moved, in: context) == nil)
    }

    @Test func aLinkNoLongerKeptFallsBackToTheAutomaticPickForAnAsNeededMedication() throws {
        let linked = try entry(minutesBack: 10)
        let older = try entry(minutesBack: 100)
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.linkedReadingID = linked.id
        draft.readingTouched = true
        let context = context(active: active, entries: [older, linked])
        let moved = draft.movingTime(to: now.addingTimeInterval(-30 * 60), in: context)
        #expect(moved.linkedReadingID == nil)
        #expect(!moved.noReading)
        #expect(resolved(moved, in: context) == older.id)
    }

    @Test func aLinkNoLongerKeptFallsBackToNoneForAMedicationRememberedAsNone() throws {
        let linked = try entry(minutesBack: 10)
        let remembered = remembering(asNeeded, .none)
        let active = [remembered]
        var draft = untouched(active: active)
        draft.noReading = false
        draft.linkedReadingID = linked.id
        draft.readingTouched = true
        let moved = draft.movingTime(
            to: now.addingTimeInterval(-30 * 60), in: context(active: active, entries: [linked])
        )
        #expect(moved.noReading)
    }

    @Test func aLinkNoLongerKeptFallsBackToTheActionRowForAnAsNeededMedicationWithNoOtherEntry() throws {
        let linked = try entry(minutesBack: 10)
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.linkedReadingID = linked.id
        draft.readingTouched = true
        let context = context(active: active, entries: [linked])
        let moved = draft.movingTime(to: now.addingTimeInterval(-30 * 60), in: context)
        #expect(!moved.noReading)
        #expect(resolved(moved, in: context) == nil)
    }

    @Test func aLinkStillKeptAtTheNewTimeStays() throws {
        let linked = try entry(minutesBack: 60)
        let active = [scheduled]
        var draft = untouched(preselected: scheduled.id, active: active)
        draft.noReading = false
        draft.linkedReadingID = linked.id
        let context = context(preselected: scheduled.id, active: active, entries: [linked])
        let moved = draft.movingTime(to: now.addingTimeInterval(-30 * 60), in: context)
        #expect(moved.linkedReadingID == linked.id)
        #expect(!moved.noReading)
    }

    @Test func aManualPickThatLeavesTheWindowFallsBackToTheMedicationsStart() throws {
        let picked = try entry(minutesBack: 100)
        let active = [scheduled]
        var draft = untouched(preselected: scheduled.id, active: active)
        draft.noReading = false
        draft.manualReadingID = picked.id
        draft.readingTouched = true
        let context = context(preselected: scheduled.id, active: active, entries: [picked])
        let moved = draft.movingTime(to: now.addingTimeInterval(120 * 60), in: context)
        #expect(moved.manualReadingID == nil)
        #expect(moved.noReading)
    }

    @Test func aManualPickStillInTheWindowStays() throws {
        let picked = try entry(minutesBack: 100)
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded]
        var draft = untouched(active: active)
        draft.manualReadingID = picked.id
        let context = context(active: active, entries: [picked, newest])
        let moved = draft.movingTime(to: now.addingTimeInterval(10 * 60), in: context)
        #expect(moved.manualReadingID == picked.id)
        #expect(resolved(moved, in: context) == picked.id)
    }

    @Test func movingTimeOnARowWithNoPickLeavesTheStateAlone() throws {
        let newest = try entry(minutesBack: 10)
        let active = [asNeeded]
        let draft = untouched(active: active)
        let moved = draft.movingTime(to: now.addingTimeInterval(-3600), in: context(active: active, entries: [newest]))
        #expect(moved.manualReadingID == nil)
        #expect(moved.linkedReadingID == nil)
        #expect(!moved.noReading)
    }
}
