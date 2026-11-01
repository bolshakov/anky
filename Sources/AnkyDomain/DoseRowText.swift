// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The pain a dose row shows: the pain before the dose, and the pain after too once the dose is checked in.
public enum DosePain: Equatable, Sendable {
    case before(Severity)
    case beforeAndAfter(before: Severity, after: Severity)

    public init(_ dose: Dose) {
        if let after = dose.painAfter {
            self = .beforeAndAfter(before: dose.painBefore, after: after)
        } else {
            self = .before(dose.painBefore)
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
    public static func subtitle(for dose: Dose, words: DoseWords) -> String {
        [words.kind, words.subtitlePain(DosePain(dose))].joined(separator: " · ")
    }

    public static func spokenLabel(time: String, title: String, dose: Dose, words: DoseWords) -> String {
        "\(time). \(title). \(words.kind). \(words.spokenPain(DosePain(dose)))."
    }

    /// The medication's current name and strength, archived or not. Empty when the store holds no such medication.
    public static func title(for dose: Dose, in medications: [Medication]) -> String {
        medications.first { $0.id == dose.medicationID }?.listTitle ?? ""
    }
}
