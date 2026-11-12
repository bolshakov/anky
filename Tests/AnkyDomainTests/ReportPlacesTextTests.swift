// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportPlacesTextTests {
    private func moreLine(_ count: Int, in identifier: String) throws -> String {
        let locale = Locale(identifier: identifier)
        let language = locale.language.languageCode?.identifier ?? "en"
        return try CompiledCatalog.withBundle(language) {
            ReportPlacesText.moreLine(count: count, locale: locale, bundle: $0)
        }
    }

    @Test(arguments: [(1, "and 1 more place"), (3, "and 3 more places"), (21, "and 21 more places")])
    func theMoreLineCountsThePlacesLeftOver(count: Int, line: String) throws {
        #expect(try moreLine(count, in: "en_GB") == line)
    }

    @Test(arguments: [(1, "и ещё 1 место"), (3, "и ещё 3 места"), (5, "и ещё 5 мест"), (21, "и ещё 21 место")])
    func russianTakesItsPluralForms(count: Int, line: String) throws {
        #expect(try moreLine(count, in: "ru") == line)
    }
}
