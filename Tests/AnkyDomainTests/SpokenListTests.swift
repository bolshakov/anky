// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct SpokenListTests {
    private let english = Locale(identifier: "en")
    private let russian = Locale(identifier: "ru")

    @Test func noNameSpeaksNothing() {
        #expect(SpokenList.joined([], locale: english) == "")
    }

    @Test func oneNameStandsAlone() {
        #expect(SpokenList.joined(["Neck"], locale: english) == "Neck")
    }

    @Test func twoNamesJoinWithAndInEnglish() {
        #expect(SpokenList.joined(["Lower back", "SI joints"], locale: english) == "Lower back and SI joints")
    }

    @Test func twoNamesJoinWithAndInRussian() {
        #expect(SpokenList.joined(["Поясница", "Шея"], locale: russian) == "Поясница и шея")
    }

    @Test func threeNamesJoinWithTheEnglishSerialComma() {
        #expect(SpokenList
            .joined(["Neck", "Back", "Hips"], locale: Locale(identifier: "en_US")) == "Neck, Back, and Hips")
    }

    @Test func threeRussianNamesKeepTheFirstCapitalAndLowercaseTheRest() {
        let places = ["Верхняя часть спины", "Копчик", "Левый крестцово-подвздошный сустав"]
        #expect(SpokenList
            .joined(places, locale: russian) == "Верхняя часть спины, копчик и левый крестцово-подвздошный сустав")
    }

    @Test func oneRussianNameKeepsItsCapital() {
        #expect(SpokenList.joined(["Шея"], locale: russian) == "Шея")
    }

    @Test func noRussianNameSpeaksNothing() {
        #expect(SpokenList.joined([], locale: russian) == "")
    }

    @Test func itemsLowercaseEveryRussianItemAfterTheFirst() {
        #expect(SpokenList.items(["Шея", "Поясница", "Копчик"], locale: russian) == ["Шея", "поясница", "копчик"])
    }

    @Test func itemsOfAnEmptyRussianListStayEmpty() {
        #expect(SpokenList.items([], locale: russian) == [])
    }

    @Test func itemsLeaveEnglishCapitalsAlone() {
        #expect(SpokenList.items(["Neck", "Lower back"], locale: english) == ["Neck", "Lower back"])
    }

    @Test func itemsLowercaseOnlyTheFirstLetterOfEachLaterItem() {
        #expect(SpokenList.items(["Шея", "ЛФК и СИ"], locale: russian) == ["Шея", "лФК и СИ"])
    }
}
