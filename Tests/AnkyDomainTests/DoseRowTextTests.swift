// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseRowTextTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    /// Each kind has its own closures, and they take numbers only. A test that reads "stiffness" therefore came from
    /// the stiffness closures, not from a kind word joined to a shared phrase.
    private var words: DoseWords {
        DoseWords(
            kind: "Dose",
            subtitle: { kind in
                DosePainWords(
                    before: { "\(Self.subtitleKind(kind)) was \($0)" },
                    after: { "\(Self.subtitleKind(kind)) \($0) after" },
                    beforeAndAfter: { "\(Self.subtitleKind(kind)) \($0) before, \($1) after" }
                )
            },
            spoken: { kind in
                DosePainWords(
                    before: { "\(Self.spokenKind(kind)) was \($0) of 10" },
                    after: { "\(Self.spokenKind(kind)) \($0) after" },
                    beforeAndAfter: { "\(Self.spokenKind(kind)) \($0) before, \($1) after" }
                )
            }
        )
    }

    private static func subtitleKind(_ kind: EntryKind) -> String {
        switch kind {
        case .pain: "pain"
        case .stiffness: "stiffness"
        case .fatigue: "fatigue"
        }
    }

    private static func spokenKind(_ kind: EntryKind) -> String {
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

    @Test func aDoseWithNoReadingHasNoPainPhrase() {
        #expect(DoseRowText.painPhrase(for: readings(), words: words) == nil)
    }

    @Test func aDoseWithNoReadingSpeaksItsTitleTimeAndKind() {
        let label = DoseRowText.spokenLabel(time: "8:30", title: "Naproxen 500 mg", readings: readings(), words: words)
        #expect(label == "Naproxen 500 mg. 8:30. Dose.")
    }

    @Test(arguments: [EntryKind.pain, .stiffness, .fatigue])
    func aBeforeReadingAloneReadsTheWholePhraseOfItsKind(kind: EntryKind) throws {
        let before = try entry(kind, severity: 6)
        let phrase = "\(Self.subtitleKind(kind)) was 6"
        #expect(DoseRowText.painPhrase(for: readings(before: before), words: words) == phrase)
    }

    @Test func anAfterReadingAloneReadsThePainAfter() throws {
        let after = try entry(.pain, severity: 3)
        #expect(DoseRowText.painPhrase(for: readings(after: after), words: words) == "pain 3 after")
    }

    @Test func bothReadingsReadBeforeAndAfter() throws {
        let before = try entry(.pain, severity: 4)
        let after = try entry(.pain, severity: 3)
        let text = DoseRowText.painPhrase(for: readings(before: before, after: after), words: words)
        #expect(text == "pain 4 before, 3 after")
    }

    @Test func theKindWordFollowsTheBeforeReading() throws {
        let before = try entry(.stiffness, severity: 6)
        let after = try entry(.pain, severity: 3)
        let text = DoseRowText.painPhrase(for: readings(before: before, after: after), words: words)
        #expect(text == "stiffness 6 before, 3 after")
    }

    @Test func theSpokenLabelOfABeforeReadingReadsThePainWas() throws {
        let before = try entry(.pain, severity: 6)
        let label = DoseRowText.spokenLabel(
            time: "8:30", title: "Naproxen 500 mg", readings: readings(before: before), words: words
        )
        #expect(label == "Naproxen 500 mg. 8:30. Dose. Pain was 6 of 10.")
    }

    @Test func theSpokenLabelFollowsTheKindOfTheBeforeReading() throws {
        let before = try entry(.stiffness, severity: 6)
        let after = try entry(.pain, severity: 3)
        let label = DoseRowText.spokenLabel(
            time: "8:30", title: "Naproxen 500 mg", readings: readings(before: before, after: after), words: words
        )
        #expect(label == "Naproxen 500 mg. 8:30. Dose. Stiffness 6 before, 3 after.")
    }

    @Test func theSpokenLabelOfBothReadingsReadsBeforeAndAfter() throws {
        let before = try entry(.pain, severity: 6)
        let after = try entry(.pain, severity: 3)
        let label = DoseRowText.spokenLabel(
            time: "8:30", title: "Naproxen 500 mg", readings: readings(before: before, after: after), words: words
        )
        #expect(label == "Naproxen 500 mg. 8:30. Dose. Pain 6 before, 3 after.")
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
}
