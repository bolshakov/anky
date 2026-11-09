// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The words of a Check In info card's taken line. The app supplies the localized ones.
/// `taken` takes the day and time the system formatted, and `before` takes a reading's kind and level.
public struct CheckInInfoWords {
    public let taken: (String) -> String
    public let before: (EntryKind, Int) -> String

    public init(taken: @escaping (String) -> String, before: @escaping (EntryKind, Int) -> String) {
        self.taken = taken
        self.before = before
    }
}

public enum CheckInDayText {
    /// The day and time as the system words them: today and yesterday by their names, any other day by its date.
    /// The system reads the current date itself, so the words follow the clock and not an argument.
    public static func takenText(for takenAt: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.formattingContext = .middleOfSentence
        return formatter.string(from: takenAt)
    }

    public static func infoTaken(taken: String, before: Entry?, words: CheckInInfoWords) -> String {
        let takenLine = words.taken(taken)
        guard let before else { return takenLine }
        return "\(takenLine) \(words.before(before.kind, before.severity.value))"
    }
}
