// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum SpokenList {
    public static func joined(_ items: [String], locale: Locale) -> String {
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: items) ?? items.joined(separator: ", ")
    }
}
