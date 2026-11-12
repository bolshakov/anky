// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct ReportSeverityBlockCatalogTests {
    private func english(_ key: String.LocalizationValue) throws -> String {
        try CompiledCatalog.withBundle("en") {
            String(localized: key, bundle: $0, locale: Locale(identifier: "en"))
        }
    }

    @Test func theHeadingNamesTheScale() throws {
        #expect(try english("Severity by week heading") == "Severity by week, 0 to 10")
    }

    @Test func aKindWithNoEntryReadsAsNoneLogged() throws {
        #expect(try english("Kind none logged") == "None logged in this period")
    }
}
