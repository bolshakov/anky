// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

/// The dose model as it was before the logged moment was stored, so the file it writes has no `ZLOGGEDAT` column.
enum LegacyDoseSchema {
    @Model final class DoseRecord {
        var id: UUID
        var medicationID: UUID
        var takenAt: Date
        var checkInAfterMinutes: Int?
        var beforeReadingID: UUID?
        var afterReadingID: UUID?

        init(
            id: UUID, medicationID: UUID, takenAt: Date, checkInAfterMinutes: Int?,
            beforeReadingID: UUID?, afterReadingID: UUID?
        ) {
            self.id = id
            self.medicationID = medicationID
            self.takenAt = takenAt
            self.checkInAfterMinutes = checkInAfterMinutes
            self.beforeReadingID = beforeReadingID
            self.afterReadingID = afterReadingID
        }
    }
}

@MainActor
struct SwiftDataLegacyDoseTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func dosesStoredBeforeTheLoggedMomentOpenWithNoneAndKeepTheirFields() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let medicationID = UUID()
            let withReadings = LegacyDoseSchema.DoseRecord(
                id: UUID(), medicationID: medicationID, takenAt: date, checkInAfterMinutes: 60,
                beforeReadingID: UUID(), afterReadingID: UUID()
            )
            let sameMinute = LegacyDoseSchema.DoseRecord(
                id: UUID(), medicationID: medicationID, takenAt: date, checkInAfterMinutes: nil,
                beforeReadingID: nil, afterReadingID: nil
            )
            do {
                let container = try ModelContainer(
                    for: MedicationRecord.self, LegacyDoseSchema.DoseRecord.self,
                    configurations: ModelConfiguration(url: url)
                )
                let context = ModelContext(container)
                context.insert(withReadings)
                context.insert(sameMinute)
                try context.save()
            }

            var expected = Dose(
                id: withReadings.id, medicationID: medicationID, takenAt: date,
                beforeReadingID: withReadings.beforeReadingID
            )
            expected.checkInAfter = .oneHour
            expected.afterReadingID = withReadings.afterReadingID
            let reopened = try SwiftDataMedicationStore(url: url).doses()
            #expect(reopened.count == 2)
            #expect(reopened.contains(expected))
            #expect(reopened.contains(Dose(id: sameMinute.id, medicationID: medicationID, takenAt: date)))
        }
    }
}
