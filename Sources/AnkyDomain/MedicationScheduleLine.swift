// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum MedicationScheduleLine {
    public static func text(
        takenAs: TakenAs,
        schedule: MedicationSchedule?,
        locale: Locale,
        calendar: Calendar,
        bundle: Bundle
    ) -> String {
        switch (takenAs, schedule) {
        case (.asNeeded, _):
            String(localized: "As needed", bundle: bundle, locale: locale)
        case let (.scheduled, schedule?):
            schedule.words(locale: locale, calendar: calendar, bundle: bundle)
        case (.scheduled, nil):
            String(localized: "Not set", bundle: bundle, locale: locale)
        }
    }
}
