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

    @Test func readsEveryEntryMedicationAndDoseTheStoresHold() throws {
        let (entries, medications) = try stores()
        let data = try ExportData.read(entries: entries, medications: medications)
        #expect(try data == ExportData(
            entries: entries.load(),
            medications: medications.all(),
            doses: medications.doses()
        ))
    }

    @Test func anUnreadableEntryStoreThrowsRatherThanExportingNoEntries() throws {
        let (entries, medications) = try stores()
        entries.loadError = .unreadable
        #expect(throws: EntryStoreError.unreadable) {
            try ExportData.read(entries: entries, medications: medications)
        }
    }

    @Test func anUnreadableMedicationStoreThrowsRatherThanExportingNoMedications() throws {
        let (entries, medications) = try stores()
        medications.readFailure = true
        #expect(throws: MedicationStoreError.unreadable) {
            try ExportData.read(entries: entries, medications: medications)
        }
    }
}
