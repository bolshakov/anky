public extension EntryDraft {
    mutating func apply(_ recent: RecentEntry) {
        kind = recent.kind
        severity = recent.severity
        places = recent.places
    }
}
