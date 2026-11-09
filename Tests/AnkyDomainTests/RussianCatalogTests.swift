// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

/// The approved words are typed here on purpose, so a word changes only through a test edit that a reviewer sees.
/// Each line is a key and its Russian value, split on " => ".
private let approvedPlainValues = table("""
Today => Сегодня
Nothing logged today => Сегодня записей нет
Log how you feel => Новая запись
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
Left SI joint => Левый крестцово-подвздошный сустав
Right SI joint => Правый крестцово-подвздошный сустав
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
Можно закрепить не больше 5 мест. Чтобы добавить другое, нужно открепить одно.
Pin a shortcut => Закрепить быстрый выбор
Swipe a place right to pin it as a shortcut on New Entry. => \
Смахивание места вправо закрепляет его для быстрого выбора на экране новой записи.
Dismiss tip => Закрыть подсказку
Pinned => Закреплено
Note => Заметка
Unpinned => Откреплено
Before this dose => Перед этим приёмом
Before: fatigue %lld. => Перед приёмом: усталость %lld.
Before: pain %lld. => Перед приёмом: боль %lld.
Before: stiffness %lld. => Перед приёмом: скованность %lld.
Check In => Самочувствие
Check in => Отметить
Check in pending => Ждёт отметки самочувствия
Choose an entry => Выбор записи
Delete dose => Удалить приём
Delete this dose? This can't be undone. => Удалить этот приём? Это нельзя отменить.
Dose => Приём
Everything you log appears here, newest first. => Все записи появляются здесь, сначала новые.
Entry deleted => Запись удалена
fatigue %lld after => усталость после: %lld
Fatigue %lld after => Усталость после: %lld
fatigue %lld before, %lld after => усталость до: %1$lld, после: %2$lld
Fatigue %lld before, %lld after => Усталость до: %1$lld, после: %2$lld
Fatigue now => Усталость сейчас
fatigue was %lld => усталость была %lld
Fatigue was %lld of 10 => Усталость была %lld из 10
Opens Check In => Открывает отметку самочувствия
pain %lld after => боль после: %lld
Pain %lld after => Боль после: %lld
pain %lld before, %lld after => боль до: %1$lld, после: %2$lld
Pain %lld before, %lld after => Боль до: %1$lld, после: %2$lld
Pain now => Боль сейчас
pain was %lld => боль была %lld
Pain was %lld of 10 => Боль была %lld из 10
Save check-in => Сохранить отметку
Saved as a fatigue entry. => Сохранится как запись об усталости.
Saved as a pain entry. => Сохранится как запись о боли.
Saved as a stiffness entry. => Сохранится как запись о скованности.
Starts from your earlier entry. Change the level or places if they differ. => \
Значения взяты из прошлой записи. Уровень и места можно изменить.
stiffness %lld after => скованность после: %lld
Stiffness %lld after => Скованность после: %lld
stiffness %lld before, %lld after => скованность до: %1$lld, после: %2$lld
Stiffness %lld before, %lld after => Скованность до: %1$lld, после: %2$lld
Stiffness now => Скованность сейчас
stiffness was %lld => скованность была %lld
Stiffness was %lld of 10 => Скованность была %lld из 10
Taken %@. => Принято: %@.
Levels are 0 to 10. => Уровни от 0 до 10.
Levels are 0 to 10. Everything stays on this iPhone. => Уровни от 0 до 10. Всё остаётся на этом iPhone.
Character limit reached => Достигнут лимит символов
Log Dose => Новый приём
Log dose => Записать приём
Medication => Лекарство
No medications yet => Лекарств пока нет
Add medication => Добавить лекарство
New Medication => Новое лекарство
Name => Название
Strength, for example 500 mg => Дозировка, например 500 мг
Strength, optional => Дозировка, необязательно
Save medication => Сохранить лекарство
As needed => По необходимости
Scheduled => По расписанию
How you take it => Способ приёма
Check in after => Отметить через
After => Через
Check in later => Отметить позже
Turn it on to choose a time. => Время можно выбрать после включения.
Anky will ask how you feel after this long. => Anky спросит о самочувствии через заданное время.
Log how you feel now => Отметить самочувствие сейчас
Log how you feel, or a dose you took. Everything stays on this iPhone. => \
Отметить самочувствие или приём лекарства. Всё остаётся на этом iPhone.
More actions => Другие действия
Save dose => Сохранить приём
The entry used for this dose. Tap to open it. => Запись, использованная для этого приёма. Нажатие открывает её.
Couldn't save this check-in. Try again. => Не удалось сохранить отметку. Можно попробовать ещё раз.
Couldn't delete this dose. Try again. => Не удалось удалить этот приём. Можно попробовать ещё раз.
Couldn't delete this entry. Try again. => Не удалось удалить эту запись. Можно попробовать ещё раз.
Couldn't save this entry. Try again. => Не удалось сохранить эту запись. Можно попробовать ещё раз.
Couldn't archive this medication. Try again. => Не удалось архивировать это лекарство. Можно попробовать ещё раз.
Couldn't restore this medication. Try again. => Не удалось восстановить это лекарство. Можно попробовать ещё раз.
Couldn't save this dose. Try again. => Не удалось сохранить этот приём. Можно попробовать ещё раз.
Couldn't save this medication. Try again. => Не удалось сохранить это лекарство. Можно попробовать ещё раз.
What are you logging? => Что записать?
Your latest entry before this dose. Tap to choose another. => \
Последняя запись перед этим приёмом. Нажатие позволяет выбрать другую.
Manage => Лекарства
Medications => Лекарства
Archive => Архивировать
Archived => В архиве
Archive medication => Архивировать лекарство
Edit Medication => Изменить лекарство
Restore => Восстановить
Restore medication => Восстановить лекарство
Swipe left to restore. Doses you logged stay in History. => \
Смахивание влево восстанавливает лекарство. Записанные приёмы остаются в «Истории».
Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History. => \
Смахивание влево архивирует лекарство. Архивные лекарства не показываются при записи приёма, а \
записанные приёмы остаются в «Истории».
Add what you take, then log a dose in two taps. Everything stays on this iPhone. => \
Добавить свои лекарства, чтобы записывать приём в два касания. Всё остаётся на этом iPhone.
Time to check in => Пора отметить самочувствие
Dose deleted => Приём удалён
Edit Dose => Изменить приём
After · checked in at %@ => После · отмечено в %@
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
    + [donePlacesKey, morePlacesKey, "%lld minutes", "%lld hours", "%lld characters left"]

private let englishFormatValues = table("""
%@ of %lld => %1$@ of %2$lld
%lld of %lld => %1$lld of %2$lld
%@, %@ and %lld more => %1$@, %2$@ and %3$lld more
""")

let russian = Locale(identifier: "ru")
private let english = Locale(identifier: "en")

func table(_ text: String) -> [(key: String, value: String)] {
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
        for key in entries.keys.sorted() {
            #expect(entries[key]?.localizations?["ru"] != nil, "\(key) has no Russian value")
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
