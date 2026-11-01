// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

/// One store under test and the controls the shared suites use. Each `StoreKind` supplies its own.
@MainActor
struct StoreFixture {
    let store: any EntryStore
    let writeCount: @MainActor () -> Int
    let refuseWrites: @MainActor (Bool) -> Void
    let refuseLoads: @MainActor (EntryStoreError?) -> Void
    let reopen: @MainActor () throws -> any EntryStore
}

enum StoreKind: CaseIterable {
    case inMemory

    @MainActor
    func fixture(holding entries: [Entry]) throws -> StoreFixture {
        switch self {
        case .inMemory:
            let store = InMemoryEntryStore(entries: entries)
            return StoreFixture(
                store: store,
                writeCount: { store.writeCount },
                refuseWrites: { store.refusesWrites = $0 },
                refuseLoads: { store.loadError = $0 },
                reopen: { store }
            )
        }
    }
}
