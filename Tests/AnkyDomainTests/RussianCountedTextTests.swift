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

private let everyDaysKey = "Every %lld days at %@"

private let approvedEveryDaysValues = table("""
one => Каждые %1$lld день в %2$@
few => Каждые %1$lld дня в %2$@
many => Каждые %1$lld дней в %2$@
other => Каждые %1$lld дня в %2$@
""")

private let everyWeeksKey = "Every %lld weeks on %@ at %@"

private let approvedEveryWeeksValues = table("""
one => Каждые %1$lld неделю: %2$@, в %3$@
few => Каждые %1$lld недели: %2$@, в %3$@
many => Каждые %1$lld недель: %2$@, в %3$@
other => Каждые %1$lld недели: %2$@, в %3$@
""")

private let everyMonthsKey = "Every %lld months on day %lld at %@"

private let approvedEveryMonthsValues = table("""
one => Каждые %1$lld месяц %2$lld-го числа в %3$@
few => Каждые %1$lld месяца %2$lld-го числа в %3$@
many => Каждые %1$lld месяцев %2$lld-го числа в %3$@
other => Каждые %1$lld месяца %2$lld-го числа в %3$@
""")

struct RussianCountedTextTests {
    @Test func theCountedTextsHoldAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let counted = [(minutesKey, approvedMinutesValues), (hoursKey, approvedHoursValues),
                       (charactersLeftKey, approvedCharactersLeftValues), (everyDaysKey, approvedEveryDaysValues),
                       (everyWeeksKey, approvedEveryWeeksValues), (everyMonthsKey, approvedEveryMonthsValues)]
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

    @Test func theEnglishScheduleSentencesTakeTheirCountedForms() throws {
        try CompiledCatalog.withBundle("en") { en in
            let english = Locale(identifier: "en")
            let days = String(localized: "Every \(2) days at \("08:00")", bundle: en, locale: english)
            let weeks = String(localized: "Every \(3) weeks on \("Friday") at \("08:00")", bundle: en, locale: english)
            let months = String(localized: "Every \(2) months on day \(9) at \("08:00")", bundle: en, locale: english)
            #expect([days, weeks, months] == ["Every 2 days at 08:00", "Every 3 weeks on Friday at 08:00",
                                              "Every 2 months on day 9 at 08:00"])
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
