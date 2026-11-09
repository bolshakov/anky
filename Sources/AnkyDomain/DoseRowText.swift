// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The pain a dose row shows. When there is a before-reading, its kind is the one shown.
public enum DosePain: Equatable, Sendable {
    case before(EntryKind, Severity)
    case after(EntryKind, Severity)
    case beforeAndAfter(EntryKind, before: Severity, after: Severity)

    /// The kind the row shows: the before reading's when there is one.
    public var kind: EntryKind {
        switch self {
        case let .before(kind, _), let .after(kind, _), let .beforeAndAfter(kind, _, _): kind
        }
    }

    public init?(_ readings: DoseReadings) {
        switch (readings.before, readings.after) {
        case let (before?, after?):
            self = .beforeAndAfter(before.kind, before: before.severity, after: after.severity)
        case let (before?, nil):
            self = .before(before.kind, before.severity)
        case let (nil, after?):
            self = .after(after.kind, after.severity)
        case (nil, nil):
            return nil
        }
    }
}

/// One whole phrase per reading case of a kind. Each takes only the numbers, so no kind word is joined into a phrase.
public struct DosePainWords {
    public let before: (Int) -> String
    public let after: (Int) -> String
    public let beforeAndAfter: (_ before: Int, _ after: Int) -> String

    public init(
        before: @escaping (Int) -> String,
        after: @escaping (Int) -> String,
        beforeAndAfter: @escaping (_ before: Int, _ after: Int) -> String
    ) {
        self.before = before
        self.after = after
        self.beforeAndAfter = beforeAndAfter
    }
}

/// The words a dose row is built from. The app supplies localized ones: the dose word, and for each kind the
/// subtitle phrases and the spoken phrases.
public struct DoseWords {
    public let kind: String
    public let subtitle: (EntryKind) -> DosePainWords
    public let spoken: (EntryKind) -> DosePainWords

    public init(
        kind: String,
        subtitle: @escaping (EntryKind) -> DosePainWords,
        spoken: @escaping (EntryKind) -> DosePainWords
    ) {
        self.kind = kind
        self.subtitle = subtitle
        self.spoken = spoken
    }
}

public enum DoseRowText {
    public static func painPhrase(for readings: DoseReadings, words: DoseWords) -> String? {
        DosePain(readings).map { phrase($0, words.subtitle($0.kind)) }
    }

    public static func spokenLabel(time: String, title: String, readings: DoseReadings, words: DoseWords) -> String {
        let head = "\(words.kind). \(title). \(time)."
        guard let pain = DosePain(readings) else { return head }
        return "\(head) \(phrase(pain, words.spoken(pain.kind)))."
    }

    private static func phrase(_ pain: DosePain, _ words: DosePainWords) -> String {
        switch pain {
        case let .before(_, level): words.before(level.value)
        case let .after(_, level): words.after(level.value)
        case let .beforeAndAfter(_, before, after): words.beforeAndAfter(before.value, after.value)
        }
    }

    /// The medication's current name and strength, archived or not. Empty when the store holds no such medication.
    public static func title(for dose: Dose, in medications: [Medication]) -> String {
        medications.first { $0.id == dose.medicationID }?.listTitle ?? ""
    }
}
