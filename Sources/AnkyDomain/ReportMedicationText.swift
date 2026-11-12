// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One medication row of the report as the page prints it. A pain or time figure with no qualifying dose reads "–".
public struct ReportMedicationRowText: Equatable, Sendable {
    public let name: String, kind: String
    public let doses: String, perWeek: String, withAfter: String, before: String, after: String, time: String

    private static let none = "–"

    public init(_ row: ReportMedicationRow, locale: Locale, bundle: Bundle) {
        name = row.medication.listTitle
        kind = switch row.medication.takenAs {
        case .asNeeded: String(localized: "As needed", bundle: bundle, locale: locale)
        case .scheduled: String(localized: "Scheduled", bundle: bundle, locale: locale)
        }
        doses = row.doseCount.formatted(.number.locale(locale))
        perWeek = row.perWeek.formatted(.number.precision(.fractionLength(1)).locale(locale))
        withAfter = row.afterReadingCount.formatted(.number.locale(locale))
        before = Self.pain(row.before, locale: locale, bundle: bundle)
        after = Self.pain(row.after, locale: locale, bundle: bundle)
        time = Self.time(row.averageTimeToAfter, locale: locale, bundle: bundle)
    }

    private static func pain(_ range: ReportPainRange?, locale: Locale, bundle: Bundle) -> String {
        guard let range else { return none }
        guard range.count > 1 else { return range.lowest.formatted(.number.locale(locale)) }
        let average = range.average.formatted(.number.precision(.fractionLength(1)).locale(locale))
        return String(localized: "\(average) (\(range.lowest)–\(range.highest))", bundle: bundle, locale: locale)
    }

    /// Rounded to a whole minute first, so 59.5 minutes reads "1 h" and never "60 min".
    private static func time(_ seconds: TimeInterval?, locale: Locale, bundle: Bundle) -> String {
        guard let seconds else { return none }
        let total = Int((seconds / 60).rounded())
        let (hours, minutes) = total.quotientAndRemainder(dividingBy: 60)
        if hours == 0 {
            return String(localized: "\(minutes) min to the after-reading", bundle: bundle, locale: locale)
        }
        if minutes == 0 {
            return String(localized: "\(hours) h to the after-reading", bundle: bundle, locale: locale)
        }
        return String(localized: "\(hours) h \(minutes) min to the after-reading", bundle: bundle, locale: locale)
    }
}

/// The line under the report's medication table.
public enum ReportMedicationNote {
    public static func text(hasScheduled: Bool, locale: Locale, bundle: Bundle) -> String {
        if hasScheduled {
            return String(
                localized: """
                Averages use only doses that have both a before and an after reading (the fourth column). \
                Pain is 0 to 10. A scheduled medication often has no after-reading.
                """,
                bundle: bundle,
                locale: locale
            )
        }
        return String(
            localized: """
            Averages use only doses that have both a before and an after reading (the fourth column). \
            Pain is 0 to 10.
            """,
            bundle: bundle,
            locale: locale
        )
    }
}
