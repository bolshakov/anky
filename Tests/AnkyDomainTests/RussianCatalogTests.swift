import Foundation
import Testing

/// The approved words are typed here on purpose, so a word changes only through a test edit that a reviewer sees.
/// Each line is a key and its Russian value, split on " => ".
private let approvedPlainValues = table("""
Today => Сегодня
Nothing logged today => Сегодня записей нет
Log how you feel => Отметь самочувствие
Log how you feel, or a medication you took. Everything stays on this iPhone. => \
Отмечай самочувствие и записывай принятые лекарства. Все данные хранятся только на этом iPhone
Stored on this iPhone only. => Хранится только на этом iPhone.
New Entry => Новая запись
Cancel => Отмена
Kind => Тип
Pain => Боль
Stiffness => Скованность
Fatigue => Усталость
Date and time => Дата и время
How strong => Насколько сильно
Severity => Сила симптома
Add a note => Добавить заметку
Limit reached => Достигнут лимит символов
Save entry => Сохранить запись
This entry could not be saved. => Не удалось сохранить запись.
OK => ОК
selected => выбрано
not selected => не выбрано
""")

private let approvedFormatValues = table("""
%@ of %lld => %1$@ из %2$lld
%lld of %lld => %1$lld из %2$lld
""")

private let counterKey = "%lld left"

private let approvedCounterValues = table("""
one => Остался %lld символ
few => Осталось %lld символа
many => Осталось %lld символов
other => Осталось %lld символа
""")

private let approvedKeys = approvedPlainValues.map(\.key) + approvedFormatValues.map(\.key) + [counterKey]

private let englishFormatValues = table("""
%@ of %lld => %1$@ of %2$lld
%lld of %lld => %1$lld of %2$lld
%@, %@ => %1$@, %2$@
%@, %@, %@, %@ => %1$@, %2$@, %3$@, %4$@
""")

private let russian = Locale(identifier: "ru")
private let english = Locale(identifier: "en")

private func table(_ text: String) -> [(key: String, value: String)] {
    text.split(separator: "\n").map {
        let parts = $0.components(separatedBy: " => ")
        return (key: parts[0], value: parts[1])
    }
}

struct RussianCatalogTests {
    @Test func everyApprovedTextReadsAsTheStakeholderWroteIt() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for (key, value) in approvedPlainValues {
                #expect(ru.localizedString(forKey: key, value: nil, table: nil) == value)
            }
        }
    }

    @Test func theSeverityTextReadsFourFromTenInBothKeys() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let format = ru.localizedString(forKey: "%@ of %lld", value: nil, table: nil)
            #expect(String(format: format, "4", 10) == "4 из 10")
            #expect(String(localized: "\(4) of \(10)", bundle: ru, locale: russian) == "4 из 10")
        }
    }

    @Test func everyApprovedRussianValueIsMarkedTranslated() throws {
        let entries = try CompiledCatalog.entries()
        for key in approvedKeys {
            let localization = try #require(entries[key]?.localizations?["ru"])
            let units = localization.stringUnits
            #expect(!units.isEmpty)
            #expect(units.allSatisfy { $0.state == "translated" })
        }
    }

    @Test func noTextOutsideTheApprovedListHasARussianValue() throws {
        let entries = try CompiledCatalog.entries()
        let keysWithRussian = entries.filter { $0.value.localizations?["ru"] != nil }.keys
        #expect(Set(keysWithRussian) == Set(approvedKeys))
    }

    @Test func oneAndTwentyOneLeftTakeTheSingularForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [1, 21] {
                #expect(String(localized: "\(count) left", bundle: ru, locale: russian) == "Остался \(count) символ")
            }
        }
    }

    @Test func twoAndTwentyTwoLeftTakeTheFewForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [2, 3, 4, 22] {
                #expect(String(localized: "\(count) left", bundle: ru, locale: russian) == "Осталось \(count) символа")
            }
        }
    }

    @Test func fiveAndTheTeensLeftTakeTheManyForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [5, 11, 12, 13, 14, 20] {
                #expect(String(localized: "\(count) left", bundle: ru, locale: russian) == "Осталось \(count) символов")
            }
        }
    }

    @Test func theCatalogHoldsAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let plural = try #require(entries[counterKey]?.localizations?["ru"]?.variations?.plural)
        #expect(Set(plural.keys) == ["one", "few", "many", "other"])
        for (form, value) in approvedCounterValues {
            #expect(plural[form]?.stringUnit?.value == value)
        }
    }

    @Test func englishReadsAsBefore() throws {
        try CompiledCatalog.withBundle("en") { en in
            for (key, _) in approvedPlainValues {
                #expect(en.localizedString(forKey: key, value: nil, table: nil) == key)
            }
            for (key, value) in englishFormatValues {
                #expect(en.localizedString(forKey: key, value: nil, table: nil) == value)
            }
            for (count, expected) in [(1, "1 left"), (5, "5 left")] {
                #expect(String(localized: "\(count) left", bundle: en, locale: english) == expected)
            }
        }
    }
}
