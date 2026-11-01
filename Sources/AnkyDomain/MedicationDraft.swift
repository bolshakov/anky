// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct MedicationDraft: Equatable, Sendable {
    public var name: String
    public var strength: String
    public var takenAs: TakenAs
    public var checkInAfter: CheckInDelay?

    public init() {
        name = ""
        strength = ""
        takenAs = .asNeeded
        checkInAfter = nil
    }

    public init(_ medication: Medication) {
        name = medication.name
        strength = medication.strength ?? ""
        takenAs = medication.takenAs
        checkInAfter = medication.checkInAfter
    }

    public var isSavable: Bool {
        !trimmed(name).isEmpty
    }

    public func medication(id: UUID, at date: Date) -> Medication {
        applied(to: Medication(id: id, name: "", takenAs: takenAs, createdAt: date), at: date)
    }

    /// Keeps the id, the created time and the archived time, and moves the updated time to `date`.
    public func applied(to medication: Medication, at date: Date) -> Medication {
        var updated = medication
        updated.name = trimmed(name)
        let strengthText = trimmed(strength)
        updated.strength = strengthText.isEmpty ? nil : strengthText
        updated.takenAs = takenAs
        updated.checkInAfter = checkInAfter
        updated.updatedAt = date
        return updated
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
