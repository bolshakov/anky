// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

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

public extension RecentEntry {
    func chipText(words: RecentWords) -> String {
        let kindPart = showsKind ? [words.kind(kind)] : []
        let placesPart = kind.asksWhere ? [chipPlaces(words)] : []
        return (kindPart + placesPart + [String(severity.value)]).joined(separator: " · ")
    }

    func spokenText(words: RecentWords) -> String {
        let kindPart = showsKind ? [words.kind(kind)] : []
        return (kindPart + spokenNames(words) + [words.level(severity)]).joined(separator: ", ")
    }

    func spokenPlaces(words: RecentWords, wholeBody: String, locale: Locale) -> String {
        guard kind.asksWhere else { return wholeBody }
        if showsNoPlace {
            return words.noPlace
        }
        return SpokenList.joined(names.map(words.name), locale: locale)
    }

    private func chipPlaces(_ words: RecentWords) -> String {
        if showsNoPlace {
            return words.noPlace
        }
        let listed = shownNames.map(words.name).joined(separator: ", ")
        return hiddenCount > 0 ? "\(listed) +\(hiddenCount)" : listed
    }

    private func spokenNames(_ words: RecentWords) -> [String] {
        guard kind.asksWhere else { return [] }
        return showsNoPlace ? [words.noPlace] : names.map(words.name)
    }
}
