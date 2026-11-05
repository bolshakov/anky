// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct CheckInDelayCatalogTests {
    @Test func theDelayTitlesReadAsBeforeInEnglish() throws {
        try CompiledCatalog.withBundle("en") { en in
            let english = Locale(identifier: "en")
            #expect(String(localized: "\(30) minutes", bundle: en, locale: english) == "30 minutes")
            for (count, expected) in [(1, "1 hour"), (2, "2 hours"), (4, "4 hours")] {
                #expect(String(localized: "\(count) hours", bundle: en, locale: english) == expected)
            }
        }
    }

    @Test func theDelayTitlesTakeTheRussianPluralForms() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let russian = Locale(identifier: "ru")
            #expect(String(localized: "\(30) minutes", bundle: ru, locale: russian) == "30 минут")
            for (count, expected) in [(1, "1 час"), (2, "2 часа"), (3, "3 часа"), (4, "4 часа")] {
                #expect(String(localized: "\(count) hours", bundle: ru, locale: russian) == expected)
            }
        }
    }
}
