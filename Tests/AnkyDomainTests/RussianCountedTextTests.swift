// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

private let minutesKey = "%lld minutes"

private let approvedMinutesValues = table("""
one => %lld минута
few => %lld минуты
many => %lld минут
other => %lld минуты
""")

private let hoursKey = "%lld hours"

private let approvedHoursValues = table("""
one => %lld час
few => %lld часа
many => %lld часов
other => %lld часа
""")

private let charactersLeftKey = "%lld characters left"

private let approvedCharactersLeftValues = table("""
one => Остался %lld символ
few => Осталось %lld символа
many => Осталось %lld символов
other => Осталось %lld символа
""")

struct RussianCountedTextTests {
    @Test func theCountedTextsHoldAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let counted = [(minutesKey, approvedMinutesValues), (hoursKey, approvedHoursValues),
                       (charactersLeftKey, approvedCharactersLeftValues)]
        for (key, approved) in counted {
            let plural = try #require(entries[key]?.localizations?["ru"]?.variations?.plural)
            #expect(Set(plural.keys) == ["one", "few", "many", "other"], "\(key) lacks a plural form")
            for (form, value) in approved {
                #expect(plural[form]?.stringUnit?.value == value)
            }
        }
    }

    @Test func minutesAndHoursTakeTheFormOfTheirCount() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let minutes = [(1, "минута"), (2, "минуты"), (5, "минут"), (11, "минут"), (21, "минута"), (30, "минут")]
            for (count, word) in minutes {
                #expect(String(localized: "\(count) minutes", bundle: ru, locale: russian) == "\(count) \(word)")
            }
            let hours = [(1, "час"), (2, "часа"), (4, "часа"), (5, "часов"), (11, "часов"), (21, "час"), (22, "часа")]
            for (count, word) in hours {
                #expect(String(localized: "\(count) hours", bundle: ru, locale: russian) == "\(count) \(word)")
            }
        }
    }

    @Test func charactersLeftTakeTheFormOfTheirCount() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let left = [(1, "Остался 1 символ"), (2, "Осталось 2 символа"), (5, "Осталось 5 символов"),
                        (11, "Осталось 11 символов"), (21, "Остался 21 символ"), (22, "Осталось 22 символа")]
            for (count, expected) in left {
                #expect(String(localized: "\(count) characters left", bundle: ru, locale: russian) == expected)
            }
        }
    }

    @Test func aTakenTimeKeepsItsPlaceholder() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let format = ru.localizedString(forKey: "Taken %@.", value: nil, table: nil)
            #expect(String(format: format, "9:30") == "Принято: 9:30.")
        }
    }

    @Test func aReadingKeepsItsNumberOutOfTen() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let readings = [("Pain was %lld of 10", "Боль была 4 из 10"),
                            ("Stiffness was %lld of 10", "Скованность была 4 из 10"),
                            ("Fatigue was %lld of 10", "Усталость была 4 из 10")]
            for (key, expected) in readings {
                #expect(String(format: ru.localizedString(forKey: key, value: nil, table: nil), 4) == expected)
            }
        }
    }

    @Test func aBeforeAndAfterReadingKeepsBothNumbersInTheirOrder() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let readings = [("Pain %lld before, %lld after", "Боль до: 3, после: 7"),
                            ("stiffness %lld before, %lld after", "скованность до: 3, после: 7"),
                            ("Fatigue %lld before, %lld after", "Усталость до: 3, после: 7")]
            for (key, expected) in readings {
                #expect(String(format: ru.localizedString(forKey: key, value: nil, table: nil), 3, 7) == expected)
            }
        }
    }
}
