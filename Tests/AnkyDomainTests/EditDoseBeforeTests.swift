// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct EditDoseBeforeTests {
    private let doseTime = Date(timeIntervalSince1970: 1_800_000_000)

    private func entry(minutesBefore minutes: Double) throws -> Entry {
        try Entry(
            id: UUID(), kind: .pain, severity: #require(Severity(4)),
            date: doseTime.addingTimeInterval(-minutes * 60), note: nil, places: []
        )
    }

    @Test func aLinkThatIsStillKeptOpensAsThatEntry() throws {
        let linked = try entry(minutesBefore: 10)
        let state = EditDoseBefore.opening(savedLink: linked.id, in: [linked], at: doseTime)
        #expect(state == .entry(linked.id))
    }

    @Test func aLinkToADeletedEntryOpensAsNoneEvenWithAnEmptyWindow() {
        let state = EditDoseBefore.opening(savedLink: UUID(), in: [], at: doseTime)
        #expect(state == .none)
    }

    @Test func noLinkWithEntriesInTheWindowOpensAsNone() throws {
        let inWindow = try entry(minutesBefore: 30)
        #expect(EditDoseBefore.opening(savedLink: nil, in: [inWindow], at: doseTime) == .none)
    }

    @Test func noLinkWithAnEmptyWindowOpensAsThePrompt() throws {
        let tooOld = try entry(minutesBefore: 180)
        let afterTheDose = try entry(minutesBefore: -5)
        #expect(EditDoseBefore.opening(savedLink: nil, in: [tooOld, afterTheDose], at: doseTime) == .prompt)
        #expect(EditDoseBefore.opening(savedLink: nil, in: [], at: doseTime) == .prompt)
    }

    @Test func anEntryStateShowsItsEntryWhileTheTimeKeepsIt() throws {
        let linked = try entry(minutesBefore: 10)
        let state = EditDoseBefore.entry(linked.id)
        #expect(state.linkedID(in: [linked], at: doseTime) == linked.id)
        #expect(!state.isNone(in: [linked], at: doseTime))
    }

    @Test func aTimeMovedBeforeTheEntryShowsNoneAndMovedBackShowsTheEntryAgain() throws {
        let linked = try entry(minutesBefore: 10)
        let state = EditDoseBefore.entry(linked.id)
        let earlier = doseTime.addingTimeInterval(-20 * 60)
        #expect(state.linkedID(in: [linked], at: earlier) == nil)
        #expect(state.isNone(in: [linked], at: earlier))
        #expect(state.linkedID(in: [linked], at: doseTime) == linked.id)
    }

    @Test func aDeletedEntryLeavesNoneAndNotThePrompt() throws {
        let linked = try entry(minutesBefore: 10)
        let state = EditDoseBefore.entry(linked.id)
        #expect(state.linkedID(in: [], at: doseTime) == nil)
        #expect(state.isNone(in: [], at: doseTime))
    }

    @Test func noneStaysNoneWhateverTheEntriesAre() throws {
        let inWindow = try entry(minutesBefore: 10)
        #expect(EditDoseBefore.none.isNone(in: [], at: doseTime))
        #expect(EditDoseBefore.none.isNone(in: [inWindow], at: doseTime))
        #expect(EditDoseBefore.none.linkedID(in: [inWindow], at: doseTime) == nil)
    }

    @Test func thePromptStaysThePromptWhenEntriesAppearInTheWindow() throws {
        let inWindow = try entry(minutesBefore: 10)
        #expect(!EditDoseBefore.prompt.isNone(in: [inWindow], at: doseTime))
        #expect(EditDoseBefore.prompt.linkedID(in: [inWindow], at: doseTime) == nil)
    }
}
