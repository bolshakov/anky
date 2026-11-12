// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct RussianPluralCatalogTests {
    @Test func everyCountedKeyHoldsAllFourRussianPluralForms() throws {
        let entries = try CompiledCatalog.entries()
        let counted = entries.filter {
            !awaitingRussian.contains($0.key) && $0.value.localizations?.values
                .contains { $0.variations != nil } == true
        }
        for key in counted.keys.sorted() {
            let plural = counted[key]?.localizations?["ru"]?.variations?.plural ?? [:]
            let forms = plural.filter { $0.value.stringUnit != nil }.keys
            #expect(Set(forms) == ["one", "few", "many", "other"], "\(key) lacks a Russian plural form")
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
}
