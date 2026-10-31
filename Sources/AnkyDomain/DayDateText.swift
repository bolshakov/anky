// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DayDateText {
    public static func text(for day: Date, includesYear: Bool, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide)
        if includesYear {
            style = style.year()
        }
        var text = day.formatted(style.attributed)
        let weekdays = text.runs.compactMap { run in
            run[AttributeScopes.FoundationAttributes.DateFieldAttribute.self] == .weekday ? run.range : nil
        }
        for range in weekdays.reversed() {
            let word = String(text[range].characters)
            text.replaceSubrange(range, with: AttributedString(capitalised(word, locale: locale)))
        }
        return String(text.characters)
    }

    private static func capitalised(_ word: String, locale: Locale) -> String {
        String(word.prefix(1)).uppercased(with: locale) + String(word.dropFirst()).lowercased(with: locale)
    }
}
