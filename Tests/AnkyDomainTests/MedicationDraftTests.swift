// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct MedicationDraftTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func draft(name: String, strength: String = "") -> MedicationDraft {
        var draft = MedicationDraft()
        draft.name = name
        draft.strength = strength
        return draft
    }

    @Test func aNewDraftHasNoNameAndIsNotSavable() {
        let draft = MedicationDraft()
        #expect(draft.name == "")
        #expect(!draft.isSavable)
    }

    @Test(arguments: ["", "   ", "\n\t "])
    func aBlankNameIsNotSavable(name: String) {
        #expect(!draft(name: name).isSavable)
    }

    @Test func aNameWithTextIsSavable() {
        #expect(draft(name: "Zorblex").isSavable)
    }

    @Test func aNameIsSavedTrimmed() {
        let saved = draft(name: "  Zorblex \n").medication(id: UUID(), at: date)
        #expect(saved.name == "Zorblex")
    }

    @Test func aStrengthIsSavedTrimmed() {
        let saved = draft(name: "Zorblex", strength: " 5 mg ").medication(id: UUID(), at: date)
        #expect(saved.strength == "5 mg")
    }

    @Test(arguments: ["", "   ", "\t"])
    func aBlankStrengthIsSavedAsNone(strength: String) {
        let saved = draft(name: "Zorblex", strength: strength).medication(id: UUID(), at: date)
        #expect(saved.strength == nil)
    }

    @Test func aNameInAnotherScriptWithAnEmojiIsSavedAsTyped() {
        let name = "Зорблекс 🌿"
        let saved = draft(name: name, strength: "5 мг").medication(id: UUID(), at: date)
        #expect(saved.name == name)
        #expect(saved.strength == "5 мг")
    }

    @Test func aSavedMedicationKeepsTheIdAndUsesTheDateForBothTimes() throws {
        let id = UUID()
        let saved = draft(name: "Zorblex").medication(id: id, at: date)
        #expect(saved.id == id)
        #expect(saved.createdAt == date)
        #expect(saved.updatedAt == date)
        #expect(saved.archivedAt == nil)
    }

    @Test func aNewDraftIsTakenAsNeededWithNoCheckIn() {
        let saved = draft(name: "Zorblex").medication(id: UUID(), at: date)
        #expect(saved.takenAs == .asNeeded)
        #expect(saved.checkInAfter == nil)
    }

    @Test func aSavedMedicationKeepsHowItIsTakenAndItsCheckIn() {
        var draft = draft(name: "Zorblex")
        draft.takenAs = .scheduled
        draft.checkInAfter = .twoHours
        let saved = draft.medication(id: UUID(), at: date)
        #expect(saved.takenAs == .scheduled)
        #expect(saved.checkInAfter == .twoHours)
    }
}
