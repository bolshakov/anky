public struct RecentWords {
    public let kind: (EntryKind) -> String
    public let name: (RecentName) -> String
    public let level: (Severity) -> String
    public let noPlace: String

    public init(
        kind: @escaping (EntryKind) -> String,
        name: @escaping (RecentName) -> String,
        level: @escaping (Severity) -> String,
        noPlace: String
    ) {
        self.kind = kind
        self.name = name
        self.level = level
        self.noPlace = noPlace
    }
}

extension RecentEntry {
    public func chipText(words: RecentWords) -> String {
        let kindPart = showsKind ? [words.kind(kind)] : []
        let placesPart = kind.asksWhere ? [chipPlaces(words)] : []
        return (kindPart + placesPart + [String(severity.value)]).joined(separator: " · ")
    }

    public func spokenText(words: RecentWords) -> String {
        ([words.kind(kind)] + spokenPlaces(words) + [words.level(severity)]).joined(separator: ", ")
    }

    private func chipPlaces(_ words: RecentWords) -> String {
        if showsNoPlace {
            return words.noPlace
        }
        let listed = shownNames.map(words.name).joined(separator: ", ")
        return hiddenCount > 0 ? "\(listed) +\(hiddenCount)" : listed
    }

    private func spokenPlaces(_ words: RecentWords) -> [String] {
        guard kind.asksWhere else { return [] }
        return showsNoPlace ? [words.noPlace] : names.map(words.name)
    }
}
