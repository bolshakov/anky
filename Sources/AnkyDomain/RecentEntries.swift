public enum RecentEntries {
    public static func distinct(from entries: [Entry], limit: Int) -> [RecentEntry] {
        guard limit > 0 else { return [] }
        let recent = newestFirst(entries).map(RecentEntry.init)
        return Array(firstOfEachGroup(recent).prefix(limit))
    }

    private static func newestFirst(_ entries: [Entry]) -> [Entry] {
        entries.enumerated()
            .sorted { ($0.element.date, $0.offset) > ($1.element.date, $1.offset) }
            .map(\.element)
    }

    private static func firstOfEachGroup(_ recent: [RecentEntry]) -> [RecentEntry] {
        var seen = Set<RecentEntry>()
        return recent.filter { seen.insert($0).inserted }
    }
}
