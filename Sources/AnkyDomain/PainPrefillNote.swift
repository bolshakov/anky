// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// When the entry a Pain before was filled from happened, as the Log Dose footnote words it. The app supplies the
/// words.
public struct PainPrefillNote: Equatable, Sendable {
    public let day: ShortDay
    public let clock: String

    public init(day: ShortDay, clock: String) {
        self.day = day
        self.clock = clock
    }

    public init(entry: Entry, now: Date, calendar: Calendar, locale: Locale) {
        self.init(
            day: ShortDayText.day(for: entry.date, now: now, calendar: calendar, locale: locale),
            clock: ClockText.text(for: entry.date, calendar: calendar, locale: locale)
        )
    }
}
