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

    public var isSavable: Bool {
        !trimmed(name).isEmpty
    }

    public func medication(id: UUID, at date: Date) -> Medication {
        var medication = Medication(id: id, name: trimmed(name), takenAs: takenAs, createdAt: date)
        let strengthText = trimmed(strength)
        medication.strength = strengthText.isEmpty ? nil : strengthText
        medication.checkInAfter = checkInAfter
        return medication
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
