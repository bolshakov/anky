import AnkyDomain
import Foundation

private let pluralJointNames = keyed(
    ("si", "SI joints"),
    ("hip", "Hips"),
    ("shoulder", "Shoulders"),
    ("elbow", "Elbows"),
    ("wrist", "Wrists"),
    ("hand", "Hands and fingers"),
    ("knee", "Knees"),
    ("ankle", "Ankles"),
    ("foot", "Feet and toes"),
    ("heel", "Heels")
)

private func keyed(_ pairs: (String, LocalizedStringResource)...) -> [String: LocalizedStringResource] {
    Dictionary(uniqueKeysWithValues: pairs)
}

extension Joint {
    var pluralDisplayName: LocalizedStringResource {
        pluralJointNames[rawValue] ?? displayName
    }
}

extension RecentWords {
    static var app: RecentWords {
        RecentWords(
            kind: { String(localized: $0.displayName) },
            name: { name in
                switch name {
                case let .place(place): String(localized: place.displayName)
                case let .pair(joint): String(localized: joint.pluralDisplayName)
                }
            },
            level: { String(localized: $0.spokenValue) },
            noPlace: String(localized: "No place")
        )
    }
}

extension RecentEntry {
    var chipText: String {
        chipText(words: .app)
    }

    var spokenText: String {
        spokenText(words: .app)
    }
}

enum RecentEntryText {
    static var sameAsLastTime: String {
        String(localized: "Same as last time")
    }
}
