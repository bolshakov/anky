// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

/// The medication model as it was before the remembered reading choice, so the file it writes has no such column.
enum LegacyScheduledMedicationSchema {
    @Model final class MedicationRecord {
        var id: UUID
        var name: String
        var strength: String?
        var takenAs: String
        var checkInAfterMinutes: Int?
        var createdAt: Date
        var updatedAt: Date
        var archivedAt: Date?
        var schedule: Data?

        init(id: UUID, name: String, takenAs: String, createdAt: Date) {
            self.id = id
            self.name = name
            self.takenAs = takenAs
            self.createdAt = createdAt
            updatedAt = createdAt
        }
    }
}

@MainActor
struct SwiftDataLegacyReadingMemoryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func aMedicationStoredBeforeTheChoiceOpensWithTheChoiceAbsentAndLogsOnToTheNewField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let legacy = LegacyScheduledMedicationSchema.MedicationRecord(
                id: UUID(), name: "Zorblex", takenAs: TakenAs.asNeeded.rawValue, createdAt: date
            )
            do {
                let container = try ModelContainer(
                    for: LegacyScheduledMedicationSchema.MedicationRecord.self, DoseRecord.self,
                    configurations: ModelConfiguration(url: url)
                )
                let context = ModelContext(container)
                context.insert(legacy)
                try context.save()
            }

            let expected = Medication(id: legacy.id, name: "Zorblex", takenAs: .asNeeded, createdAt: date)
            let store = try SwiftDataMedicationStore(url: url)
            #expect(try store.all() == [expected])
            #expect(try store.all().first?.readingMemory == nil)

            try store.logDose(Dose(id: UUID(), medicationID: legacy.id, takenAt: date), remembering: .entry)
            #expect(try SwiftDataMedicationStore(url: url).all().first?.readingMemory == .entry)
        }
    }

    @Test func aStoredValueTheAppDoesNotKnowReadsAsUnreadable() throws {
        let record = try MedicationRecord(Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: date))
        record.readingMemory = "sometimes"
        #expect(throws: MedicationStoreError.unreadable) { try record.medication() }
    }
}
