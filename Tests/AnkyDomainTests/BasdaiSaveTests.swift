// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct BasdaiSaveTests {
    private struct Refused: Error {}

    private let answers = [4, 6, 3, 5, 7, 4]
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func savingAddsOneResultDatedNowWithTheAnswers() throws {
        var added: [BasdaiResult] = []
        var save = BasdaiSave()

        let saved = try save.save(answers, at: now) { added.append($0) }

        #expect(saved)
        let result = try #require(added.first)
        #expect(added.count == 1)
        #expect(result.answers == answers)
        #expect(result.date == now)
        #expect(result.createdAt == now)
        #expect(result.updatedAt == now)
    }

    @Test func aSecondTapAfterASaveAddsNothing() throws {
        var added: [BasdaiResult] = []
        var save = BasdaiSave()

        _ = try save.save(answers, at: now) { added.append($0) }
        let again = try save.save(answers, at: now) { added.append($0) }

        #expect(!again)
        #expect(added.count == 1)
    }

    @Test func aRefusedWriteLeavesTheSaveOpenForARetry() throws {
        var added: [BasdaiResult] = []
        var save = BasdaiSave()

        #expect(throws: Refused.self) {
            try save.save(answers, at: now) { _ in throw Refused() }
        }
        let retried = try save.save(answers, at: now) { added.append($0) }

        #expect(retried)
        #expect(added.map(\.answers) == [answers])
    }

    @Test func answersThatAreNotSixFromZeroToTenAreRefusedAndAddNothing() {
        var added: [BasdaiResult] = []
        var save = BasdaiSave()

        #expect(throws: BasdaiStoreError.notSaved) {
            try save.save([4, 6, 3], at: now) { added.append($0) }
        }
        #expect(added.isEmpty)
    }
}
