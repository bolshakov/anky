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

    @Test func aSavedMedicationKeepsTheIdAndUsesTheDateForBothTimes() {
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
        draft.checkIn = DoseCheckIn(savedDelay: .twoHours)
        let saved = draft.medication(id: UUID(), at: date)
        #expect(saved.takenAs == .scheduled)
        #expect(saved.checkInAfter == .twoHours)
    }

    @Test func aDraftWithTheCheckInSwitchedOffSavesNoDelay() {
        var draft = draft(name: "Zorblex")
        draft.checkIn = DoseCheckIn(savedDelay: .threeHours)
        draft.checkIn.isOn = false
        #expect(draft.medication(id: UUID(), at: date).checkInAfter == nil)
    }

    @Test(arguments: CheckInDelay.allCases)
    func aMedicationWithASavedDelayOpensWithTheCheckInOnAtThatDelay(_ delay: CheckInDelay) {
        var medication = existing()
        medication.checkInAfter = delay
        let draft = MedicationDraft(medication)
        #expect(draft.checkIn.isOn)
        #expect(draft.checkIn.delay == delay)
        #expect(draft.applied(to: medication, at: date).checkInAfter == delay)
    }

    @Test func switchingOnAtFourHoursThenOffThenOnKeepsFourHours() {
        var draft = draft(name: "Zorblex")
        draft.checkIn.isOn = true
        draft.checkIn.delay = .fourHours
        draft.checkIn.isOn = false
        draft.checkIn.isOn = true
        #expect(draft.checkIn.delay == .fourHours)
        #expect(draft.medication(id: UUID(), at: date).checkInAfter == .fourHours)
    }

    private func existing(strength: String? = "25 mg") -> Medication {
        var medication = Medication(
            id: UUID(),
            name: "Zorblex",
            takenAs: .asNeeded,
            createdAt: date.addingTimeInterval(-600)
        )
        medication.strength = strength
        medication.checkInAfter = .oneHour
        medication.archivedAt = date.addingTimeInterval(-300)
        return medication
    }

    @Test func aDraftOfAMedicationCopiesEveryEditableField() {
        let medication = existing()
        let draft = MedicationDraft(medication)
        #expect(draft.name == "Zorblex")
        #expect(draft.strength == "25 mg")
        #expect(draft.takenAs == .asNeeded)
        #expect(draft.checkIn == DoseCheckIn(savedDelay: .oneHour))
    }

    @Test func aDraftOfAMedicationWithNoStrengthHasAnEmptyStrength() {
        #expect(MedicationDraft(existing(strength: nil)).strength == "")
    }

    @Test func applyingADraftChangesTheEditableFieldsAndMovesTheUpdatedTime() {
        let medication = existing()
        var draft = MedicationDraft(medication)
        draft.name = "  Quibbanol "
        draft.strength = " 50 mg "
        draft.takenAs = .scheduled
        draft.checkIn = DoseCheckIn(savedDelay: .fourHours)
        let applied = draft.applied(to: medication, at: date)
        #expect(applied.name == "Quibbanol")
        #expect(applied.strength == "50 mg")
        #expect(applied.takenAs == .scheduled)
        #expect(applied.checkInAfter == .fourHours)
        #expect(applied.updatedAt == date)
    }

    @Test func applyingADraftKeepsTheIdCreatedTimeAndArchivedTime() {
        let medication = existing()
        let applied = MedicationDraft(medication).applied(to: medication, at: date)
        #expect(applied.id == medication.id)
        #expect(applied.createdAt == medication.createdAt)
        #expect(applied.archivedAt == medication.archivedAt)
    }

    @Test func clearingTheStrengthRemovesIt() {
        let medication = existing()
        var draft = MedicationDraft(medication)
        draft.strength = "   "
        #expect(draft.applied(to: medication, at: date).strength == nil)
    }
}
