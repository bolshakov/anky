// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What VoiceOver reads for one chart of the report: how many weeks it shows and how many of them hold an entry. It
/// holds counts only, so it never judges a week as better or worse.
public enum ReportChartSentence {
    public static func text(for figures: KindWeeklyFigures, bundle: Bundle, locale: Locale) -> String {
        let name = figures.kind.name(bundle: bundle, locale: locale)
        let weeks = String(localized: "\(figures.weeks.count) weeks", bundle: bundle, locale: locale)
        let logged = String(
            localized: "entries logged in \(figures.loggedWeekCount) of them",
            bundle: bundle,
            locale: locale
        )
        return String(localized: "\(name) by week: \(weeks), \(logged)", bundle: bundle, locale: locale)
    }
}

private extension EntryKind {
    func name(bundle: Bundle, locale: Locale) -> String {
        switch self {
        case .pain: String(localized: "Pain", bundle: bundle, locale: locale)
        case .stiffness: String(localized: "Stiffness", bundle: bundle, locale: locale)
        case .fatigue: String(localized: "Fatigue", bundle: bundle, locale: locale)
        }
    }
}
