// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A BASDAI store held in memory. Tests read `addCalls` to see every add, refused ones included.
@MainActor final class FakeBasdaiStore: BasdaiStore {
    private(set) var contents: [BasdaiResult]
    private(set) var addCalls: [BasdaiResult] = []
    /// Set to make the next writes throw. Set back to false to let them succeed.
    var writeFailure = false
    /// Set to make reads throw. Set back to false to let them succeed.
    var readFailure = false

    init(_ results: [BasdaiResult] = []) {
        contents = results
    }

    func all() throws -> [BasdaiResult] {
        if readFailure {
            throw BasdaiStoreError.unreadable
        }
        return contents
    }

    func add(_ result: BasdaiResult) throws {
        addCalls.append(result)
        if writeFailure {
            throw BasdaiStoreError.notSaved
        }
        contents.append(result)
    }

    func remove(id: UUID) throws {
        if writeFailure {
            throw BasdaiStoreError.notSaved
        }
        guard let index = contents.firstIndex(where: { $0.id == id }) else {
            throw BasdaiStoreError.notSaved
        }
        contents.remove(at: index)
    }

    func removeAll() throws {
        if writeFailure {
            throw BasdaiStoreError.notSaved
        }
        contents = []
    }
}
