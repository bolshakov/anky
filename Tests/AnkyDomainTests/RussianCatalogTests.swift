// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

/// The approved words are typed here on purpose, so a word changes only through a test edit that a reviewer sees.
/// Each line is a key and its Russian value, split on " => ".
private let approvedPlainValues = table("""
Today => Сегодня
Nothing logged today => Сегодня записей нет
Log how you feel => Отметь самочувствие
New Entry => Новая запись
Cancel => Отмена
Pain => Боль
Stiffness => Скованность
Fatigue => Усталость
Date and time => Дата и время
How strong => Насколько сильно
Severity => Сила симптома
Add a note => Добавить заметку
Save entry => Сохранить запись
OK => ОК
selected => выбрано
not selected => не выбрано
Where => Где
More places => Другие места
Search joints and places => Поиск суставов и мест
No matching places => Ничего не найдено
Done => Готово
Left => Слева
Right => Справа
Whole body => Всё тело
No place => Место не указано
Spine => Позвоночник
Pelvis and chest => Таз и грудная клетка
Arms => Руки
Legs => Ноги
Head => Голова
Neck => Шея
Upper back => Верхняя часть спины
Lower back => Поясница
Tailbone => Копчик
SI joint => Крестцово-подвздошный сустав
Hip => Тазобедренный сустав
Ribs => Рёбра
Chest wall => Грудная клетка
Shoulder => Плечо
Elbow => Локоть
Wrist => Запястье
Hand and fingers => Кисть и пальцы
Knee => Колено
Ankle => Голеностоп
Foot and toes => Стопа и пальцы ног
Heel => Пятка
Jaw => Челюсть
Eyes => Глаза
Left SI joint => Левый крестцово-подвздошный
Right SI joint => Правый крестцово-подвздошный
Left hip => Левый тазобедренный сустав
Right hip => Правый тазобедренный сустав
Left shoulder => Левое плечо
Right shoulder => Правое плечо
Left elbow => Левый локоть
Right elbow => Правый локоть
Left wrist => Левое запястье
Right wrist => Правое запястье
Left hand and fingers => Левая кисть и пальцы
Right hand and fingers => Правая кисть и пальцы
Left knee => Левое колено
Right knee => Правое колено
Left ankle => Левый голеностоп
Right ankle => Правый голеностоп
Left foot and toes => Левая стопа и пальцы ног
Right foot and toes => Правая стопа и пальцы ног
Left heel => Левая пятка
Right heel => Правая пятка
Edit Entry => Изменить запись
Save changes => Сохранить изменения
Delete => Удалить
Delete entry => Удалить запись
Delete this entry? This can't be undone. => Удалить эту запись? Это нельзя отменить.
History => История
Yesterday => Вчера
No entries yet => Записей пока нет
None => Нет
Same as last time => Как в прошлый раз
Logged => Записано
Undo => Отменить
SI joints => Крестцово-подвздошные суставы
Hips => Тазобедренные суставы
Shoulders => Плечи
Elbows => Локти
Wrists => Запястья
Hands and fingers => Кисти и пальцы
Knees => Колени
Ankles => Голеностопы
Feet and toes => Стопы и пальцы ног
Heels => Пятки
Pin => Закрепить
Unpin => Открепить
Pin as shortcut => Закрепить как быстрый выбор
Unpin shortcut => Открепить быстрый выбор
You can pin up to 5. Unpin one to add another. => \
Можно закрепить не больше 5 мест. Открепи одно, чтобы добавить другое.
Pin a shortcut => Закрепи быстрый выбор
Swipe a place right to pin it as a shortcut on New Entry. => \
Смахни место вправо, чтобы закрепить его для быстрого выбора на экране новой записи.
Dismiss tip => Закрыть подсказку
Pinned => Закреплено
Note => Заметка
Unpinned => Откреплено
""")

private let approvedFormatValues = table("""
%@ of %lld => %1$@ из %2$lld
%lld of %lld => %1$lld из %2$lld
%@, %@ and %lld more => %1$@, %2$@ и ещё %3$lld
""")

private let donePlacesKey = "Done · %lld places"

private let approvedDoneValues = table("""
one => Готово · %lld место
few => Готово · %lld места
many => Готово · %lld мест
other => Готово · %lld места
""")

private let morePlacesKey = "%lld places"

private let approvedMorePlacesValues = table("""
one => %lld место
few => %lld места
many => %lld мест
other => %lld места
""")

private let approvedKeys = approvedPlainValues.map(\.key)
    + approvedFormatValues.map(\.key)
    + [donePlacesKey, morePlacesKey, "%lld minutes", "%lld hours"]

private let englishFormatValues = table("""
%@ of %lld => %1$@ of %2$lld
%lld of %lld => %1$lld of %2$lld
%@, %@ and %lld more => %1$@, %2$@ and %3$lld more
""")

/// Keys that stay English only until t-47 gives them Russian. Removing a key from here is the step that approves it.
private let awaitingRussian = ["Log Dose", "Log dose", "Medication"]
    + ["No medications yet", "Add medication", "New Medication", "Name", "Strength, for example 500 mg"]
    + ["Save medication", "As needed", "Scheduled"]
    + ["How you take it", "Check in after", "After"]
    + ["Check in later", "Anky will ask how you feel after this long.", "Turn it on to choose a time."]
    + ["Manage", "Medications", "Archive", "Archived"]
    + ["Edit Medication", "Archive medication", "Restore", "Restore medication"]
    + ["Swipe left to restore. Doses you logged stay in History."]
    + ["Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History."]
    + ["Add what you take, then log a dose in two taps. Everything stays on this iPhone."]
    + ["Couldn't save this medication. Try again.", "Couldn't archive this medication. Try again."]
    + ["Save dose", "Couldn't save this dose. Try again."]
    + ["Couldn't restore this medication. Try again.", "Strength, optional"]
    + ["Before this dose", "Your latest entry before this dose. Tap to choose another."]
    + ["Edit Dose", "checked in at", "The entry used for this dose. Tap to open it."]
    + ["Choose an entry", "Log how you feel now"]
    + ["Dose", "pain was %lld", "stiffness was %lld", "fatigue was %lld"]
    + ["pain %lld after", "pain %lld before, %lld after"]
    + ["stiffness %lld after", "stiffness %lld before, %lld after"]
    + ["fatigue %lld after", "fatigue %lld before, %lld after"]
    + ["Pain was %lld of 10", "Pain %lld after", "Pain %lld before, %lld after"]
    + ["Stiffness was %lld of 10", "Stiffness %lld after", "Stiffness %lld before, %lld after"]
    + ["Fatigue was %lld of 10", "Fatigue %lld after", "Fatigue %lld before, %lld after"]
    + ["Pain now", "Stiffness now", "Fatigue now", "Save check-in", "Couldn't save this check-in. Try again."]
    + ["Starts from your earlier entry. Change the level or places if they differ."]
    + ["Saved as a pain entry.", "Saved as a stiffness entry.", "Saved as a fatigue entry."]
    + ["Taken %@.", "Before: pain %lld.", "Before: stiffness %lld.", "Before: fatigue %lld."]
    + ["Check in", "Check In", "Check in pending", "Opens Check In"]
    + ["Delete dose", "Delete this dose? This can't be undone.", "Couldn't delete this dose. Try again."]
    + ["Levels are 0 to 10. Everything stays on this iPhone.", "Levels are 0 to 10."]
    + ["Time to check in"]
    + ["More actions"]
    + ["Couldn't save this entry. Try again.", "Couldn't delete this entry. Try again."]
    + ["Entry deleted", "Dose deleted", "%lld characters left", "Character limit reached"]
    + ["Everything you log appears here, newest first.", "What are you logging?"]
    + ["Log how you feel, or a dose you took. Everything stays on this iPhone."]

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
        let unapproved = Set(keysWithRussian).subtracting(approvedKeys)
        #expect(unapproved.isEmpty, "Russian values outside the approved list: \(unapproved.sorted())")
    }

    @Test func everyKeyOfTheCatalogHasARussianValue() throws {
        let entries = try CompiledCatalog.entries()
        for key in entries.keys.sorted() where !awaitingRussian.contains(key) {
            #expect(entries[key]?.localizations?["ru"] != nil, "\(key) has no Russian value")
        }
    }

    @Test func noAwaitingKeyHasARussianValueYet() throws {
        let entries = try CompiledCatalog.entries()
        for key in awaitingRussian {
            #expect(entries[key]?.localizations?["ru"] == nil, "\(key) has a Russian value; approve it in the list")
        }
    }

    @Test func oneAndTwentyOnePlacesTakeTheSingularForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [1, 21] {
                #expect(String(localized: "Done · \(count) places", bundle: ru, locale: russian) ==
                    "Готово · \(count) место")
            }
        }
    }

    @Test func twoAndTwentyTwoPlacesTakeTheFewForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [2, 3, 4, 22] {
                #expect(String(localized: "Done · \(count) places", bundle: ru, locale: russian) ==
                    "Готово · \(count) места")
            }
        }
    }

    @Test func fiveAndTheTeensPlacesTakeTheManyForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [5, 11, 12, 13, 14, 20] {
                #expect(String(localized: "Done · \(count) places", bundle: ru, locale: russian) ==
                    "Готово · \(count) мест")
            }
        }
    }

    @Test func theDoneButtonHoldsAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let plural = try #require(entries[donePlacesKey]?.localizations?["ru"]?.variations?.plural)
        #expect(Set(plural.keys) == ["one", "few", "many", "other"])
        for (form, value) in approvedDoneValues {
            #expect(plural[form]?.stringUnit?.value == value)
        }
    }

    @Test func theCountOfPlacesHoldsAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let plural = try #require(entries[morePlacesKey]?.localizations?["ru"]?.variations?.plural)
        #expect(Set(plural.keys) == ["one", "few", "many", "other"])
        for (form, value) in approvedMorePlacesValues {
            #expect(plural[form]?.stringUnit?.value == value)
        }
    }

    @Test func theCountOfPlacesTakesTheRussianPluralForms() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [1, 21] {
                #expect(String(localized: "\(count) places", bundle: ru, locale: russian) == "\(count) место")
            }
            for count in [2, 3, 4, 22] {
                #expect(String(localized: "\(count) places", bundle: ru, locale: russian) == "\(count) места")
            }
            for count in [5, 11, 12, 13, 14, 20] {
                #expect(String(localized: "\(count) places", bundle: ru, locale: russian) == "\(count) мест")
            }
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
            for (count, expected) in [(1, "1 character left"), (5, "5 characters left")] {
                #expect(String(localized: "\(count) characters left", bundle: en, locale: english) == expected)
            }
            for (count, expected) in [(1, "Done · 1 place"), (5, "Done · 5 places")] {
                #expect(String(localized: "Done · \(count) places", bundle: en, locale: english) == expected)
            }
            for (count, expected) in [(1, "1 place"), (6, "6 places")] {
                #expect(String(localized: "\(count) places", bundle: en, locale: english) == expected)
            }
        }
    }
}
