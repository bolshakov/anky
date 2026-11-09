// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum SpokenList {
    public static func joined(_ items: [String], locale: Locale) -> String {
        let items = Self.items(items, locale: locale)
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: items) ?? items.joined(separator: ", ")
    }

    public static func items(_ items: [String], locale: Locale) -> [String] {
        guard locale.language.languageCode?.identifier == "ru" else { return items }
        return items.enumerated().map { index, item in
            index == 0 ? item : lowercasingFirstLetter(item, locale: locale)
        }
    }

    private static func lowercasingFirstLetter(_ item: String, locale: Locale) -> String {
        item.prefix(1).lowercased(with: locale) + item.dropFirst()
    }
}
