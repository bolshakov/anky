// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor
struct ExportDataReadTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)

    private func stores() throws -> (entries: InMemoryEntryStore, medications: FakeMedicationStore) {
        let entry = try Entry(
            id: UUID(),
            kind: .pain,
            severity: #require(Severity(6)),
            date: morning,
            note: nil,
            places: []
        )
        let medication = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: morning)
        let dose = Dose(id: UUID(), medicationID: medication.id, takenAt: morning, beforeReadingID: entry.id)
        return (InMemoryEntryStore(entries: [entry]), FakeMedicationStore([medication], doses: [dose]))
    }

    private func basdaiStore() -> FakeBasdaiStore {
        FakeBasdaiStore([madeUpBasdai(date: morning, answers: [4, 6, 3, 5, 7, 4])])
    }

    @Test func readsEveryEntryMedicationDoseAndBasdaiResultTheStoresHold() throws {
        let (entries, medications) = try stores()
        let basdai = basdaiStore()
        let data = try ExportData.read(entries: entries, medications: medications, basdai: basdai)
        #expect(try data == ExportData(
            entries: entries.load(),
            medications: medications.all(),
            doses: medications.doses(),
            basdai: basdai.all()
        ))
        #expect(data.basdai.count == 1)
    }

    @Test func anUnreadableEntryStoreThrowsRatherThanExportingNoEntries() throws {
        let (entries, medications) = try stores()
        let basdai = basdaiStore()
        entries.loadError = .unreadable
        #expect(throws: EntryStoreError.unreadable) {
            try ExportData.read(entries: entries, medications: medications, basdai: basdai)
        }
    }

    @Test func anUnreadableMedicationStoreThrowsRatherThanExportingNoMedications() throws {
        let (entries, medications) = try stores()
        let basdai = basdaiStore()
        medications.readFailure = true
        #expect(throws: MedicationStoreError.unreadable) {
            try ExportData.read(entries: entries, medications: medications, basdai: basdai)
        }
    }

    @Test func anUnreadableBasdaiStoreThrowsRatherThanExportingNoResults() throws {
        let (entries, medications) = try stores()
        let basdai = basdaiStore()
        basdai.readFailure = true
        #expect(throws: BasdaiStoreError.unreadable) {
            try ExportData.read(entries: entries, medications: medications, basdai: basdai)
        }
    }
}
