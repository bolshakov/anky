// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct BasdaiLogTests {
    private let morning = Date(timeIntervalSince1970: 1_800_000_000)
    private let evening = Date(timeIntervalSince1970: 1_800_036_000)

    @Test func loadsTheSavedResultsNewestFirst() {
        let older = madeUpBasdai(date: morning)
        let newer = madeUpBasdai(date: evening)
        let log = BasdaiLog(store: FakeBasdaiStore([older, newer]))
        #expect(log.results == [newer, older])
    }

    @Test func twoResultsWithTheSameDateListTheLaterCreatedFirst() throws {
        let first = madeUpBasdai(date: morning, createdAt: morning)
        let second = madeUpBasdai(date: morning, createdAt: morning.addingTimeInterval(20))
        var log = BasdaiLog(store: FakeBasdaiStore([second]))
        try log.add(first)
        #expect(log.results == [second, first])
        #expect(BasdaiLog(store: FakeBasdaiStore([first, second])).results == [second, first])
    }

    @Test func startsEmptyWhenTheStoreCannotBeRead() {
        let store = FakeBasdaiStore([madeUpBasdai()])
        store.readFailure = true
        #expect(BasdaiLog(store: store).results.isEmpty)
    }

    @Test func addSavesTheResultAndPlacesItByDate() throws {
        let newer = madeUpBasdai(date: evening)
        let older = madeUpBasdai(date: morning)
        let store = FakeBasdaiStore([newer])
        var log = BasdaiLog(store: store)
        try log.add(older)
        #expect(log.results == [newer, older])
        #expect(store.contents == [newer, older])
    }

    @Test func aRefusedAddLeavesTheListAsItWasAndARetrySavesIt() throws {
        let saved = madeUpBasdai(date: morning)
        let store = FakeBasdaiStore([saved])
        var log = BasdaiLog(store: store)
        let tapped = madeUpBasdai(date: evening)
        store.writeFailure = true
        #expect(throws: BasdaiStoreError.notSaved) { try log.add(tapped) }
        #expect(log.results == [saved])
        store.writeFailure = false
        try log.add(tapped)
        #expect(log.results == [tapped, saved])
        #expect(store.contents == [saved, tapped])
    }

    @Test func addOfAnIdTheLogHoldsDoesNotReachTheStore() throws {
        let saved = madeUpBasdai()
        let store = FakeBasdaiStore([saved])
        var log = BasdaiLog(store: store)
        try log.add(saved)
        #expect(log.results == [saved])
        #expect(store.addCalls.isEmpty)
    }

    @Test func removeTakesOutOnlyThatResult() throws {
        let kept = madeUpBasdai(date: morning)
        let removed = madeUpBasdai(date: evening)
        let store = FakeBasdaiStore([kept, removed])
        var log = BasdaiLog(store: store)
        try log.remove(id: removed.id)
        #expect(log.results == [kept])
        #expect(store.contents == [kept])
    }

    @Test func aRefusedRemoveLeavesTheListAsItWas() {
        let saved = madeUpBasdai()
        let store = FakeBasdaiStore([saved])
        var log = BasdaiLog(store: store)
        store.writeFailure = true
        #expect(throws: BasdaiStoreError.notSaved) { try log.remove(id: saved.id) }
        #expect(log.results == [saved])
    }

    @Test func removeOfAnUnknownIdDoesNothing() throws {
        let saved = madeUpBasdai()
        let store = FakeBasdaiStore([saved])
        var log = BasdaiLog(store: store)
        try log.remove(id: UUID())
        #expect(log.results == [saved])
        #expect(store.contents == [saved])
    }

    @Test func removeAllEmptiesTheListAndTheStore() throws {
        let store = FakeBasdaiStore([madeUpBasdai(), madeUpBasdai()])
        var log = BasdaiLog(store: store)
        try log.removeAll()
        #expect(log.results.isEmpty)
        #expect(store.contents.isEmpty)
    }

    @Test func aRefusedRemoveAllKeepsEveryResult() {
        let saved = [madeUpBasdai(date: evening), madeUpBasdai(date: morning)]
        let store = FakeBasdaiStore(saved)
        var log = BasdaiLog(store: store)
        store.writeFailure = true
        #expect(throws: BasdaiStoreError.notSaved) { try log.removeAll() }
        #expect(log.results == saved)
        #expect(store.contents == saved)
    }
}
