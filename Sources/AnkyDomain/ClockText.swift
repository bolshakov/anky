// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ClockText {
    public static func text(for date: Date, calendar: Calendar, locale: Locale) -> String {
        let pattern = DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: locale) ?? "HH:mm"
        return DateTemplateText.text(
            for: date,
            dateFormat: oneDigitHour(in: pattern),
            calendar: calendar,
            locale: locale
        )
    }

    private static let hourFields = ["HH": "H", "hh": "h", "KK": "K", "kk": "k"]

    /// Quoted literals sit at the odd positions of the split, so their letters are left as they are.
    private static func oneDigitHour(in pattern: String) -> String {
        var segments = pattern.components(separatedBy: "'")
        for index in segments.indices where index.isMultiple(of: 2) {
            for (field, short) in hourFields {
                segments[index] = segments[index].replacingOccurrences(of: field, with: short)
            }
        }
        return segments.joined(separator: "'")
    }
}
