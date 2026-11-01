// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseRowTextTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private var words: DoseWords {
        DoseWords(
            kind: "Dose",
            subtitlePain: { pain in
                switch pain {
                case let .before(level): "pain was \(level.value) of 10"
                case let .beforeAndAfter(before, after): "pain \(before.value) before, \(after.value) after"
                }
            },
            spokenPain: { pain in
                switch pain {
                case let .before(level): "Pain was \(level.value) of 10"
                case let .beforeAndAfter(before, after): "Pain \(before.value) before, \(after.value) after"
                }
            }
        )
    }

    private func medication(id: UUID, name: String, strength: String?, archived: Bool) -> Medication {
        var medication = Medication(id: id, name: name, takenAs: .asNeeded, createdAt: date)
        medication.strength = strength
        medication.archivedAt = archived ? date : nil
        return medication
    }

    private func dose(for medicationID: UUID, painAfter: Int? = nil) throws -> Dose {
        var dose = try Dose(
            id: UUID(),
            medicationID: medicationID,
            takenAt: date,
            painBefore: #require(Severity(6))
        )
        dose.painAfter = try painAfter.map { try #require(Severity($0)) }
        return dose
    }

    @Test func aDoseBeforeCheckInReadsThePainWas() throws {
        let dose = try dose(for: UUID())
        #expect(DoseRowText.subtitle(for: dose, words: words) == "Dose · pain was 6 of 10")
    }

    @Test func aCheckedInDoseReadsThePainBeforeAndAfter() throws {
        let dose = try dose(for: UUID(), painAfter: 3)
        #expect(DoseRowText.subtitle(for: dose, words: words) == "Dose · pain 6 before, 3 after")
    }

    @Test func theSpokenLabelReadsTimeTitleKindAndPainWas() throws {
        let dose = try dose(for: UUID())
        let label = DoseRowText.spokenLabel(time: "08:30", title: "Naproxen 500 mg", dose: dose, words: words)
        #expect(label == "08:30. Naproxen 500 mg. Dose. Pain was 6 of 10.")
    }

    @Test func theSpokenLabelOfACheckedInDoseReadsBeforeAndAfter() throws {
        let dose = try dose(for: UUID(), painAfter: 3)
        let label = DoseRowText.spokenLabel(time: "08:30", title: "Naproxen 500 mg", dose: dose, words: words)
        #expect(label == "08:30. Naproxen 500 mg. Dose. Pain 6 before, 3 after.")
    }

    @Test func theTitleIsTheDosesOwnMedicationNameAndStrength() throws {
        let first = UUID()
        let archived = UUID()
        let third = UUID()
        let naproxen = medication(id: first, name: "Naproxen", strength: "250 mg", archived: false)
        let fennimax = medication(id: archived, name: "Fennimax", strength: "500 mg", archived: true)
        let zorblex = medication(id: third, name: "Zorblex", strength: "10 mg", archived: false)
        let medications = [naproxen, fennimax, zorblex]
        let firstDose = try dose(for: first)
        let archivedDose = try dose(for: archived)
        let thirdDose = try dose(for: third)
        #expect(DoseRowText.title(for: archivedDose, in: medications) == "Fennimax 500 mg")
        #expect(DoseRowText.title(for: thirdDose, in: medications) == "Zorblex 10 mg")
        #expect(DoseRowText.title(for: firstDose, in: medications) == "Naproxen 250 mg")
    }

    @Test func aMedicationWithoutAStrengthReadsAsItsBareName() throws {
        let id = UUID()
        let medications = [medication(id: id, name: "Naproxen", strength: nil, archived: false)]
        let taken = try dose(for: id)
        #expect(DoseRowText.title(for: taken, in: medications) == "Naproxen")
    }

    @Test func aDoseOfAMedicationNotInTheListReadsAnEmptyTitle() throws {
        let medications = [medication(id: UUID(), name: "Naproxen", strength: nil, archived: false)]
        let taken = try dose(for: UUID())
        #expect(DoseRowText.title(for: taken, in: medications) == "")
    }
}
