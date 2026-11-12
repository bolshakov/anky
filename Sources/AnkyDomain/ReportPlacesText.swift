// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The line under the report's places when more were logged than it shows.
public enum ReportPlacesText {
    public static func moreLine(count: Int, locale: Locale, bundle: Bundle) -> String {
        String(localized: "and \(count) more places", bundle: bundle, locale: locale)
    }
}
