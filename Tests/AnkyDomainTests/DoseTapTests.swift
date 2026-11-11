// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseTapTests {
    private let tapped = UUID(uuidString: "0A1B2C3D-4E5F-6789-ABCD-EF0123456789")!
    private let other = UUID(uuidString: "1A1B2C3D-4E5F-6789-ABCD-EF0123456789")!
    private let created = Date(timeIntervalSince1970: 1_900_000_000)

    @Test func anActiveMedicationOpensLogDose() {
        let medications = [medication(other), medication(tapped)]
        #expect(DoseTap.opensLogDose(medicationID: tapped, medications: medications))
    }

    @Test func aMedicationArchivedAfterItsNotificationWasScheduledOpensToday() {
        var archived = medication(tapped)
        archived.archivedAt = created.addingTimeInterval(60)
        #expect(!DoseTap.opensLogDose(medicationID: tapped, medications: [archived]))
    }

    @Test func anUnknownMedicationOpensToday() {
        #expect(!DoseTap.opensLogDose(medicationID: tapped, medications: [medication(other)]))
    }

    private func medication(_ id: UUID) -> Medication {
        Medication(id: id, name: "A", takenAs: .scheduled, createdAt: created)
    }
}
