public struct EntryLog: Sendable {
    private let store: any EntryStore
    public private(set) var entries: [Entry]

    public init(store: any EntryStore) {
        self.store = store
        entries = (try? store.load()) ?? []
    }

    public mutating func add(_ entry: Entry) throws {
        guard !entries.contains(where: { $0.id == entry.id }) else { return }
        let saved = entries + [entry]
        // The list changes only after the store accepts it, so a failed save leaves the log as it was.
        try store.save(saved)
        entries = saved
    }
}
