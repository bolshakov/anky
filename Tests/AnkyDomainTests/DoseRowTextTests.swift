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
                case let .before(kind, level): "\(Self.word(kind)) was \(level.value) of 10"
                case let .after(kind, level): "\(Self.word(kind)) \(level.value) after"
                case let .beforeAndAfter(kind, before, after):
                    "\(Self.word(kind)) \(before.value) before, \(after.value) after"
                }
            },
            spokenPain: { pain in
                switch pain {
                case let .before(kind, level): "\(Self.name(kind)) was \(level.value) of 10"
                case let .after(kind, level): "\(Self.name(kind)) \(level.value) after"
                case let .beforeAndAfter(kind, before, after):
                    "\(Self.name(kind)) \(before.value) before, \(after.value) after"
                }
            }
        )
    }

    private static func word(_ kind: EntryKind) -> String {
        switch kind {
        case .pain: "pain"
        case .stiffness: "stiffness"
        case .fatigue: "fatigue"
        }
    }

    private static func name(_ kind: EntryKind) -> String {
        switch kind {
        case .pain: "Pain"
        case .stiffness: "Stiffness"
        case .fatigue: "Fatigue"
        }
    }

    private func medication(id: UUID, name: String, strength: String?, archived: Bool) -> Medication {
        var medication = Medication(id: id, name: name, takenAs: .asNeeded, createdAt: date)
        medication.strength = strength
        medication.archivedAt = archived ? date : nil
        return medication
    }

    private func entry(_ kind: EntryKind, severity: Int) throws -> Entry {
        try Entry(id: UUID(), kind: kind, severity: #require(Severity(severity)), date: date, note: nil, places: [])
    }

    private func readings(before: Entry? = nil, after: Entry? = nil) -> DoseReadings {
        var dose = Dose(id: UUID(), medicationID: UUID(), takenAt: date, beforeReadingID: before?.id)
        dose.afterReadingID = after?.id
        return DoseReadings(dose, in: [before, after].compactMap(\.self))
    }

    private func dose(for medicationID: UUID) -> Dose {
        Dose(id: UUID(), medicationID: medicationID, takenAt: date)
    }

    @Test func aDoseWithNoReadingReadsAsItsKindAlone() {
        #expect(DoseRowText.subtitle(for: readings(), words: words) == "Dose")
    }

    @Test func aDoseWithNoReadingSpeaksItsTimeTitleAndKind() {
        let label = DoseRowText.spokenLabel(time: "08:30", title: "Naproxen 500 mg", readings: readings(), words: words)
        #expect(label == "08:30. Naproxen 500 mg. Dose.")
    }

    @Test func aBeforeReadingAloneReadsThePainWas() throws {
        let before = try entry(.pain, severity: 6)
        #expect(DoseRowText.subtitle(for: readings(before: before), words: words) == "Dose · pain was 6 of 10")
    }

    @Test func anAfterReadingAloneReadsThePainAfter() throws {
        let after = try entry(.pain, severity: 3)
        #expect(DoseRowText.subtitle(for: readings(after: after), words: words) == "Dose · pain 3 after")
    }

    @Test func bothReadingsReadBeforeAndAfter() throws {
        let before = try entry(.pain, severity: 4)
        let after = try entry(.pain, severity: 3)
        let text = DoseRowText.subtitle(for: readings(before: before, after: after), words: words)
        #expect(text == "Dose · pain 4 before, 3 after")
    }

    @Test func theKindWordFollowsTheBeforeReading() throws {
        let before = try entry(.stiffness, severity: 6)
        let after = try entry(.pain, severity: 3)
        let text = DoseRowText.subtitle(for: readings(before: before, after: after), words: words)
        #expect(text == "Dose · stiffness 6 before, 3 after")
    }

    @Test func theSpokenLabelOfABeforeReadingReadsThePainWas() throws {
        let before = try entry(.pain, severity: 6)
        let label = DoseRowText.spokenLabel(
            time: "08:30", title: "Naproxen 500 mg", readings: readings(before: before), words: words
        )
        #expect(label == "08:30. Naproxen 500 mg. Dose. Pain was 6 of 10.")
    }

    @Test func theSpokenLabelOfBothReadingsReadsBeforeAndAfter() throws {
        let before = try entry(.pain, severity: 6)
        let after = try entry(.pain, severity: 3)
        let label = DoseRowText.spokenLabel(
            time: "08:30", title: "Naproxen 500 mg", readings: readings(before: before, after: after), words: words
        )
        #expect(label == "08:30. Naproxen 500 mg. Dose. Pain 6 before, 3 after.")
    }

    @Test func theTitleIsTheDosesOwnMedicationNameAndStrength() {
        let first = UUID()
        let archived = UUID()
        let third = UUID()
        let naproxen = medication(id: first, name: "Naproxen", strength: "250 mg", archived: false)
        let fennimax = medication(id: archived, name: "Fennimax", strength: "500 mg", archived: true)
        let zorblex = medication(id: third, name: "Zorblex", strength: "10 mg", archived: false)
        let medications = [naproxen, fennimax, zorblex]
        #expect(DoseRowText.title(for: dose(for: archived), in: medications) == "Fennimax 500 mg")
        #expect(DoseRowText.title(for: dose(for: third), in: medications) == "Zorblex 10 mg")
        #expect(DoseRowText.title(for: dose(for: first), in: medications) == "Naproxen 250 mg")
    }

    @Test func aMedicationWithoutAStrengthReadsAsItsBareName() {
        let id = UUID()
        let medications = [medication(id: id, name: "Naproxen", strength: nil, archived: false)]
        #expect(DoseRowText.title(for: dose(for: id), in: medications) == "Naproxen")
    }

    @Test func aDoseOfAMedicationNotInTheListReadsAnEmptyTitle() {
        let medications = [medication(id: UUID(), name: "Naproxen", strength: nil, archived: false)]
        #expect(DoseRowText.title(for: dose(for: UUID()), in: medications) == "")
    }

    @Test func theNameLeavesOutTheStrength() {
        let id = UUID()
        let medications = [medication(id: id, name: "Naproxen", strength: "500 mg", archived: false)]
        #expect(DoseRowText.name(for: dose(for: id), in: medications) == "Naproxen")
    }

    @Test func aDoseOfAMedicationNotInTheListReadsAnEmptyName() {
        let medications = [medication(id: UUID(), name: "Naproxen", strength: nil, archived: false)]
        #expect(DoseRowText.name(for: dose(for: UUID()), in: medications) == "")
    }
}
