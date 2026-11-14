// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

/// The report, its PDF and the erase alerts, typed here on purpose like the other approved values. Each line is a key
/// and its Russian value, split on " => ".
let reportRussianValues = table("""
%@ to %@ => С %1$@ по %2$@
Anky is a personal log kept by the patient. It does not give medical advice. => \
Anky — личный журнал, который ведёт сам пациент. Не заменяет консультацию врача.
BASDAI results => Результаты BASDAI
Counts, averages and ranges only. => Только количество, средние значения и диапазоны.
created %@ => создан %@
First entry %@ => Первая запись: %@
Get Anky on the App Store => Anky в App Store
Include BASDAI scores => Добавить результаты BASDAI
Kind none logged => За этот период записей нет
Legend lowest to highest => от наименьшего до наибольшего
Legend none logged => записей нет
Legend number under a bar => число под столбцом: записей за неделю
Legend one entry => одна запись
Legend weekly average => среднее за неделю
Made with Anky, page %lld of %lld => \
Создано в Anky, бесплатном журнале симптомов для iPhone · anky.bolshakov.dev · Страница %1$lld из %2$lld
Name line => Имя
Recorded by the patient in Anky. => Записано пациентом в Anky.
Severity by week heading => Сила симптома по неделям, от 0 до 10
Shows the scores saved in this period. Everything stays on this iPhone until you share the report. => \
Показывает результаты, сохранённые за этот период. Всё остаётся на этом iPhone, пока ты не поделишься отчётом.
Symptom report => Отчёт о симптомах
Week count none => –
Erase every entry, dose, medication and BASDAI result on this iPhone? This can't be undone. => \
Стереть все данные на этом iPhone: записи, приёмы, лекарства и результаты BASDAI? Это нельзя отменить.
Your entries were erased, but your medications, doses and BASDAI results were not. Try again to erase the rest. => \
Записи стёрты, но лекарства, приёмы и результаты BASDAI остались. Попробуй стереть остальное ещё раз.
Your entries, doses and medications were erased, but your BASDAI results were not. Try again to erase the rest. => \
Записи, приёмы и лекарства стёрты, но результаты BASDAI остались. Попробуй стереть остальное ещё раз.
Q%lld %@ => В%1$lld %2$@
%@. Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). => \
%@. Каждый ответ от 0 до 10; результат = (В1 + В2 + В3 + В4 + (В5 + В6) / 2) / 5. \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
Places logged => Записанные места
Place => Место
Entries => Записи
None logged in this period => За этот период записей нет
BASDAI scores => Результаты BASDAI
BASDAI scores, continued => Результаты BASDAI, продолжение
Date => Дата
Q%lld => В%lld
""")

let basdaiResultsKey = "%lld BASDAI results"

let approvedBasdaiResultsValues = table("""
one => %lld результат BASDAI
few => %lld результата BASDAI
many => %lld результатов BASDAI
other => %lld результата BASDAI
""")

struct RussianReportValuesTests {
    @Test func theTableHoldsThirtyFourKeys() {
        #expect(reportRussianValues.count == 34)
        #expect(Set(reportRussianValues.map(\.key)).count == 34)
    }

    @Test func everyReportPdfAndEraseTextReadsAsTheStakeholderWroteIt() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for (key, value) in reportRussianValues {
                #expect(ru.localizedString(forKey: key, value: nil, table: nil) == value, "\(key) reads differently")
            }
        }
    }

    @Test func thePeriodUnderTheTitleKeepsTheEnglishOrderOfItsDates() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let format = ru.localizedString(forKey: "%@ to %@", value: nil, table: nil)
            #expect(String(format: format, "11 августа 2026", "11 ноября 2026") ==
                "С 11 августа 2026 по 11 ноября 2026")
        }
    }

    @Test func theFooterOfPageTwoOfThreeReadsPageTwoOfThree() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let format = ru.localizedString(forKey: "Made with Anky, page %lld of %lld", value: nil, table: nil)
            #expect(String(format: format, 2, 3).hasSuffix("Страница 2 из 3"))
        }
    }

    @Test func aQuestionLabelKeepsTheEnglishOrderOfItsNumberAndName() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            let format = ru.localizedString(forKey: "Q%lld %@", value: nil, table: nil)
            #expect(String(format: format, 2, "Боль в шее, спине, тазобедренных суставах") ==
                "В2 Боль в шее, спине, тазобедренных суставах")
        }
    }

    @Test func theBasdaiResultsCountHoldsAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let plural = try #require(entries[basdaiResultsKey]?.localizations?["ru"]?.variations?.plural)
        #expect(Set(plural.keys) == ["one", "few", "many", "other"])
        for (form, value) in approvedBasdaiResultsValues {
            #expect(plural[form]?.stringUnit?.value == value)
            #expect(plural[form]?.stringUnit?.state == "translated")
        }
    }

    @Test func oneAndTwentyOneBasdaiResultsTakeTheSingularForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [1, 21] {
                #expect(String(localized: "\(count) BASDAI results", bundle: ru, locale: russian) ==
                    "\(count) результат BASDAI")
            }
        }
    }

    @Test func twoThreeFourAndTwentyTwoBasdaiResultsTakeTheFewForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [2, 3, 4, 22] {
                #expect(String(localized: "\(count) BASDAI results", bundle: ru, locale: russian) ==
                    "\(count) результата BASDAI")
            }
        }
    }

    @Test func fiveTheTeensAndTwentyBasdaiResultsTakeTheManyForm() throws {
        try CompiledCatalog.withBundle("ru") { ru in
            for count in [5, 11, 12, 13, 14, 20] {
                #expect(String(localized: "\(count) BASDAI results", bundle: ru, locale: russian) ==
                    "\(count) результатов BASDAI")
            }
        }
    }
}
