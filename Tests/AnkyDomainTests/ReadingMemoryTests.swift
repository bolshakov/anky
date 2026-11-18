// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReadingMemoryTests {
    private func medication(_ takenAs: TakenAs, remembering memory: ReadingMemory? = nil) -> Medication {
        var medication = Medication(
            id: UUID(),
            name: "Name",
            takenAs: takenAs,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        medication.readingMemory = memory
        return medication
    }

    private func entry() throws -> Entry {
        try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(4)),
            date: Date(timeIntervalSince1970: 1_800_000_000),
            note: nil,
            places: []
        )
    }

    @Test func aNewMedicationRemembersNothing() {
        #expect(medication(.asNeeded).readingMemory == nil)
        #expect(medication(.scheduled).readingMemory == nil)
    }

    @Test func aScheduledMedicationWithNoMemoryStartsWithNone() {
        #expect(ReadingStart.forMedication(medication(.scheduled)) == .none)
    }

    @Test func anAsNeededMedicationWithNoMemoryStartsAutomatic() {
        #expect(ReadingStart.forMedication(medication(.asNeeded)) == .automatic)
    }

    @Test func noMedicationStartsAutomatic() {
        #expect(ReadingStart.forMedication(nil) == .automatic)
    }

    @Test(arguments: TakenAs.allCases)
    func aRememberedNoneStartsWithNoneOnEveryKind(takenAs: TakenAs) {
        #expect(ReadingStart.forMedication(medication(takenAs, remembering: ReadingMemory.none)) == .none)
    }

    @Test(arguments: TakenAs.allCases)
    func aRememberedEntryStartsAutomaticOnEveryKind(takenAs: TakenAs) {
        #expect(ReadingStart.forMedication(medication(takenAs, remembering: .entry)) == .automatic)
    }

    @Test func noReadingIsRememberedAsNoneEvenWithAnEntryResolved() throws {
        #expect(try ReadingMemory.toRemember(noReading: true, resolved: entry()) == ReadingMemory.none)
        #expect(ReadingMemory.toRemember(noReading: true, resolved: nil) == ReadingMemory.none)
    }

    @Test func aResolvedEntryIsRememberedAsEntry() throws {
        #expect(try ReadingMemory.toRemember(noReading: false, resolved: entry()) == .entry)
    }

    @Test func neitherNoReadingNorAnEntryRemembersNothing() {
        #expect(ReadingMemory.toRemember(noReading: false, resolved: nil) == nil)
    }

    @Test(arguments: TakenAs.allCases)
    func changingTheKindKeepsTheMemory(takenAs: TakenAs) {
        var changed = medication(takenAs, remembering: .entry)
        changed.takenAs = takenAs == .asNeeded ? .scheduled : .asNeeded
        #expect(changed.readingMemory == .entry)
        #expect(ReadingStart.forMedication(changed) == .automatic)
    }
}
