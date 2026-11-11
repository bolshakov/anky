// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

@MainActor struct DeferredBasdaiStoreTests {
    private struct Locked: Error {}

    @Test func aStoreThatCannotOpenThrowsUnavailableAndOpensOnALaterCall() throws {
        let saved = madeUpBasdai()
        let inner = FakeBasdaiStore([saved])
        var locked = true
        var attempts = 0
        let store = DeferredBasdaiStore {
            attempts += 1
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: BasdaiStoreError.unavailable) { try store.all() }
        locked = false
        #expect(try store.all() == [saved])
        #expect(attempts == 2)
    }

    @Test func anOpenedStoreIsNotOpenedAgain() throws {
        var attempts = 0
        let store = DeferredBasdaiStore {
            attempts += 1
            return FakeBasdaiStore()
        }
        _ = try store.all()
        try store.add(madeUpBasdai())
        _ = try store.all()
        #expect(attempts == 1)
    }

    @Test func aWriteWhileLockedNeverReachesTheStoreAndSucceedsOnceOpened() throws {
        let inner = FakeBasdaiStore()
        var locked = true
        let store = DeferredBasdaiStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        let result = madeUpBasdai()
        #expect(throws: BasdaiStoreError.unavailable) { try store.add(result) }
        #expect(inner.addCalls.isEmpty)
        locked = false
        try store.add(result)
        #expect(inner.contents == [result])
    }

    @Test func removeForwardsThroughTheOpenedStore() throws {
        let kept = madeUpBasdai()
        let removed = madeUpBasdai()
        let inner = FakeBasdaiStore([kept, removed])
        let store = DeferredBasdaiStore { inner }
        try store.remove(id: removed.id)
        #expect(inner.contents == [kept])
    }

    @Test func removeWhileLockedNeverReachesTheStore() {
        let saved = madeUpBasdai()
        let inner = FakeBasdaiStore([saved])
        let store = DeferredBasdaiStore { throw Locked() }
        #expect(throws: BasdaiStoreError.unavailable) { try store.remove(id: saved.id) }
        #expect(inner.contents == [saved])
    }

    @Test func removeAllOnAStoreThatCannotOpenThrowsUnavailableAndChangesNothing() throws {
        let saved = madeUpBasdai()
        let inner = FakeBasdaiStore([saved])
        var locked = true
        let store = DeferredBasdaiStore {
            if locked {
                throw Locked()
            }
            return inner
        }
        #expect(throws: BasdaiStoreError.unavailable) { try store.removeAll() }
        #expect(inner.contents == [saved])
        locked = false
        try store.removeAll()
        #expect(inner.contents.isEmpty)
    }
}
