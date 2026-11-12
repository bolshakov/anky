// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct ReportFooterCatalogTests {
    @Test func thePageLineReadsInFullWithItsNumbers() throws {
        let line = try CompiledCatalog.withBundle("en") {
            String(localized: "Made with Anky, page \(2) of \(3)", bundle: $0, locale: Locale(identifier: "en"))
        }
        #expect(line == "Made with Anky, a free symptom log for iPhone · anky.bolshakov.dev · Page 2 of 3")
    }
}
