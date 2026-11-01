// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct DoseSaveTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func dose(id: UUID) throws -> Dose {
        try Dose(id: id, medicationID: UUID(), takenAt: date, painBefore: #require(Severity(4)))
    }

    @Test func aSecondSaveAfterASuccessLogsNothing() throws {
        var logged: [Dose] = []
        var save = DoseSave()
        let first = try dose(id: UUID())
        #expect(try save.save(first, log: { logged.append($0) }))
        #expect(try !save.save(dose(id: UUID()), log: { logged.append($0) }))
        #expect(logged == [first])
        #expect(save.isSaved)
    }

    @Test func aFailedLogLeavesTheSaveOpenAndTheRetryLogsTheSameDose() throws {
        var logged: [Dose] = []
        var refused = true
        var save = DoseSave()
        let pending = try dose(id: UUID())
        #expect(throws: MedicationStoreError.notSaved) {
            try save.save(pending, log: { _ in
                if refused {
                    throw MedicationStoreError.notSaved
                }
            })
        }
        #expect(!save.isSaved)

        refused = false
        #expect(try save.save(pending, log: { logged.append($0) }))
        #expect(logged == [pending])
    }
}
