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
Save => Сохранить
Pain => Боль
Stiffness => Скованность
Fatigue => Усталость
Date and time => Дата и время
How strong => Насколько сильно
Severity => Сила симптома
Add a note => Добавить заметку
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
Before this dose => Перед этим приёмом
Before: fatigue %lld. => Перед приёмом: усталость %lld.
Before: pain %lld. => Перед приёмом: боль %lld.
Before: stiffness %lld. => Перед приёмом: скованность %lld.
Check In => Самочувствие
Check in => Отметить
Check in pending => Ждёт отметки самочувствия
Choose an Entry => Выбор записи
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
Saved as a fatigue entry. => Сохранится как запись об усталости.
Saved as a pain entry. => Сохранится как запись о боли.
Saved as a stiffness entry. => Сохранится как запись о скованности.
Starts from your earlier entry. Change the level or places if they differ. => \
Взято из твоей прошлой записи. Измени уровень или места, если они другие.
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
Strength, optional => Дозировка, необязательно
As needed => По необходимости
Scheduled => По расписанию
Not set => Не задано
Schedule => Расписание
Repeat => Повтор
Times => Время приёма
Add a time => Добавить время
Duration => Продолжительность
Last week => За последнюю неделю
Starts => Начало
Ends => Окончание
Every day => Каждый день
Every week => Каждую неделю
Every 2 weeks => Каждые 2 недели
Every 4 weeks => Каждые 4 недели
on => включено
off => выключено
How you take it => Способ приёма
Check in after => Отметить через
After => Через
Check in later => Отметить позже
Turn it on to choose a time. => Включи, чтобы выбрать время.
Anky will ask how you feel after this long. => Anky спросит, как ты себя чувствуешь, когда пройдёт это время.
Log how you feel now => Отметь самочувствие сейчас
Log how you feel, or a dose you took. Everything stays on this iPhone. => \
Запиши самочувствие или приём лекарства. Всё остаётся на этом iPhone.
More actions => Другие действия
The entry used for this dose. Tap to open it. => Запись, использованная для этого приёма. Нажми, чтобы открыть.
Couldn't save this check-in. Try again. => Не удалось сохранить отметку. Попробуй ещё раз.
Couldn't delete this dose. Try again. => Не удалось удалить этот приём. Попробуй ещё раз.
Couldn't delete this entry. Try again. => Не удалось удалить эту запись. Попробуй ещё раз.
Couldn't save this entry. Try again. => Не удалось сохранить эту запись. Попробуй ещё раз.
Couldn't archive this medication. Try again. => Не удалось архивировать это лекарство. Попробуй ещё раз.
Couldn't restore this medication. Try again. => Не удалось восстановить это лекарство. Попробуй ещё раз.
Couldn't save this dose. Try again. => Не удалось сохранить этот приём. Попробуй ещё раз.
Couldn't save this medication. Try again. => Не удалось сохранить это лекарство. Попробуй ещё раз.
What are you logging? => Что ты записываешь?
Your latest entry before this dose. Tap to choose another. => \
Твоя последняя запись перед этим приёмом. Нажми, чтобы выбрать другую.
Manage => Лекарства
Medications => Лекарства
Settings => Настройки
Manage medications => Лекарства
Your data => Твои данные
Your data stays on this iPhone unless you share an export. => \
Твои данные остаются на этом iPhone, пока ты не поделишься экспортом.
Erase all data => Стереть все данные
Export data => Экспортировать данные
Exporting => Идёт экспорт
Couldn't export => Не удалось экспортировать
Nothing was shared. Try again. => Ничего не отправлено. Попробуй ещё раз.
Erase => Стереть
Couldn't erase your data. Try again. => Не удалось стереть данные. Попробуй ещё раз.
All data erased => Все данные стёрты
About => О приложении
Source code and license => Исходный код и лицензия
Privacy policy => Политика конфиденциальности
Privacy Policy => Политика конфиденциальности
Version %@ (%@) => Версия %@ (%@)
Anky comes with no warranty. You may share and change it under the GNU GPL, version 3 or later. => \
Anky предоставляется без гарантий. Его можно распространять и изменять на условиях GNU GPL версии 3 или более поздней.
Archive => Архивировать
Archived => В архиве
Archive medication => Архивировать лекарство
Edit Medication => Изменить лекарство
Restore => Восстановить
Restore medication => Восстановить лекарство
Swipe left to restore. Doses you logged stay in History. => \
Смахни влево, чтобы восстановить. Записанные приёмы останутся в «Истории».
Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History. => \
Смахни влево, чтобы архивировать. Архивные лекарства не показываются при записи приёма, а записанные приёмы останутся \
в «Истории».
Add what you take, then log a dose in two taps. Everything stays on this iPhone. => \
Добавь то, что ты принимаешь, и записывай приём в два касания. Всё остаётся на этом iPhone.
Time to check in => Пора отметить самочувствие
Reminders => Напоминания
Daily reminder => Ежедневное напоминание
Off in iOS Settings => Выключено в настройках iOS
Time => Время
Skipped on days you have already logged something. => \
Пропускается в дни, когда уже есть записи.
Log how you feel today. => Пора записать самочувствие.
Time for your dose. => Пора принять лекарство.
Anky => Anky
Dose deleted => Приём удалён
Edit Dose => Изменить приём
After · checked in at %@ => После · отмечено в %@
Every day at %@ => Каждый день в %@
Every week on %@ at %@ => Каждую неделю: %1$@, в %2$@
Every month on day %lld at %@ => Каждый месяц %1$lld-го числа в %2$@
%@. Next: %@. => %1$@. Следующий приём: %2$@.
%@. => %@.
Report and BASDAI => Отчёт и BASDAI
Report for your doctor => Отчёт для врача
Report => Отчёт
Period => Период
1 month => 1 месяц
3 months => 3 месяца
6 months => 6 месяцев
Preview => Просмотреть
""") + reportDraftPlainValues

private let approvedFormatValues = table("""
%@ of %lld => %1$@ из %2$lld
%lld of %lld => %1$lld из %2$lld
%@, %@ and %lld more => %1$@, %2$@ и ещё %3$lld
%@ and %@, %@ to %@. => %1$@ и %2$@, с %3$@ по %4$@.
Nothing logged from %@ to %@. Pick a longer period. => С %1$@ по %2$@ записей нет. Выбери период длиннее.
%@ by week: %@, %@ => %1$@ по неделям: %2$@, %3$@
""") + reportDraftFormatValues

let donePlacesKey = "Done · %lld places"

let approvedDoneValues = table("""
one => Готово · %lld место
few => Готово · %lld места
many => Готово · %lld мест
other => Готово · %lld места
""")

let morePlacesKey = "%lld places"

let approvedMorePlacesValues = table("""
one => %lld место
few => %lld места
many => %lld мест
other => %lld места
""")

private let approvedKeys = approvedPlainValues.map(\.key)
    + approvedFormatValues.map(\.key)
    + [donePlacesKey, morePlacesKey, "%lld minutes", "%lld hours", "%lld characters left"]
    + ["%lld entries", "%lld doses"]
    + ["%lld weeks", "entries logged in %lld of them"]
    + ["and %lld more places"]
    + ["Every %lld days at %@", "Every %lld weeks on %@ at %@", "Every %lld months on day %lld at %@"]
    + basdaiRussianValues.map(\.key)

private let englishFormatValues = table("""
%@ of %lld => %1$@ of %2$lld
%lld of %lld => %1$lld of %2$lld
%@, %@ and %lld more => %1$@, %2$@ and %3$lld more
%@ and %@, %@ to %@. => %1$@ and %2$@, %3$@ to %4$@.
Nothing logged from %@ to %@. Pick a longer period. => Nothing logged from %1$@ to %2$@. Pick a longer period.
%@ by week: %@, %@ => %1$@ by week: %2$@, %3$@
""") + reportDraftEnglishFormatValues

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
        for key in Set(entries.keys).subtracting(awaitingRussian).sorted() {
            #expect(entries[key]?.localizations?["ru"] != nil, "\(key) has no Russian value")
        }
    }

    @Test func everyKeyAwaitingRussianIsInTheCatalogWithNoRussianValueYet() throws {
        let entries = try CompiledCatalog.entries()
        for key in awaitingRussian {
            let russianValue = try #require(entries[key], "\(key) is not in the catalog").localizations?["ru"]
            #expect(russianValue == nil, "\(key) has a Russian value, so it leaves awaitingRussian")
        }
    }

    @Test func noRussianValueIsEmpty() throws {
        let entries = try CompiledCatalog.entries()
        for key in entries.keys.sorted() {
            let units = entries[key]?.localizations?["ru"]?.stringUnits ?? []
            #expect(units.allSatisfy { !$0.value.isEmpty }, "\(key) has an empty Russian value")
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
