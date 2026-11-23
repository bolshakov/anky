// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseTapTests {
    private let tapped = UUID(uuidString: "0A1B2C3D-4E5F-6789-ABCD-EF0123456789")!
    private let other = UUID(uuidString: "1A1B2C3D-4E5F-6789-ABCD-EF0123456789")!
    private let created = Date(timeIntervalSince1970: 1_900_000_000)

    @Test func aMedicationArchivedAfterItsNotificationWasScheduledIsUnavailable() {
        var archived = medication(tapped)
        archived.archivedAt = created.addingTimeInterval(60)
        #expect(DoseTap.outcome(medicationID: tapped, medications: [archived]) == .unavailable)
    }

    @Test func aMedicationAbsentFromTheListIsUnavailable() {
        #expect(DoseTap.outcome(medicationID: tapped, medications: [medication(other)]) == .unavailable)
    }

    @Test func aMedicationAbsentFromAnEmptyListIsUnavailable() {
        #expect(DoseTap.outcome(medicationID: tapped, medications: []) == .unavailable)
    }

    @Test func aTapJudgedBeforeTheMedicationsAreAvailableWaits() {
        #expect(DoseTap.outcome(medicationID: tapped, medications: nil) == .wait)
    }

    @Test func aTapOnAnActiveMedicationOpensOnceTheListIsAvailable() {
        let medications = [medication(other), medication(tapped)]
        #expect(DoseTap.outcome(medicationID: tapped, medications: medications) == .open)
    }

    private func medication(_ id: UUID) -> Medication {
        Medication(id: id, name: "A", takenAs: .scheduled, createdAt: created)
    }
}
