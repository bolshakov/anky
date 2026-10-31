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
        #expect(SpokenList.joined(["Поясница", "Шея"], locale: russian) == "Поясница и Шея")
    }
}
