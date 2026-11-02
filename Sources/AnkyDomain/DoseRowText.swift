// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The pain a dose row shows. When there is a before-reading, its kind is the one shown.
public enum DosePain: Equatable, Sendable {
    case before(EntryKind, Severity)
    case after(EntryKind, Severity)
    case beforeAndAfter(EntryKind, before: Severity, after: Severity)

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

/// The words a dose row is built from. The app supplies localized ones.
public struct DoseWords {
    public let kind: String
    public let subtitlePain: (DosePain) -> String
    public let spokenPain: (DosePain) -> String

    public init(
        kind: String,
        subtitlePain: @escaping (DosePain) -> String,
        spokenPain: @escaping (DosePain) -> String
    ) {
        self.kind = kind
        self.subtitlePain = subtitlePain
        self.spokenPain = spokenPain
    }
}

public enum DoseRowText {
    public static func subtitle(for readings: DoseReadings, words: DoseWords) -> String {
        guard let pain = DosePain(readings) else { return words.kind }
        return [words.kind, words.subtitlePain(pain)].joined(separator: " · ")
    }

    public static func spokenLabel(time: String, title: String, readings: DoseReadings, words: DoseWords) -> String {
        let head = "\(time). \(title). \(words.kind)."
        guard let pain = DosePain(readings) else { return head }
        return "\(head) \(words.spokenPain(pain))."
    }

    /// The medication's current name and strength, archived or not. Empty when the store holds no such medication.
    public static func title(for dose: Dose, in medications: [Medication]) -> String {
        medications.first { $0.id == dose.medicationID }?.listTitle ?? ""
    }

    /// The medication's current name without its strength. Empty when the store holds no such medication.
    public static func name(for dose: Dose, in medications: [Medication]) -> String {
        medications.first { $0.id == dose.medicationID }?.name ?? ""
    }
}
