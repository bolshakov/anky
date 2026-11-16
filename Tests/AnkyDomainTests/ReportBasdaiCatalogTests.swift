// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct ReportBasdaiCatalogTests {
    private static let keys = """
    BASDAI scores
    BASDAI scores, continued
    Date
    Q%lld
    """.split(separator: "\n").map(String.init)

    @Test(arguments: keys)
    func theBasdaiBlockStringReadsAsItsKeyInEnglishWithAComment(key: String) throws {
        let entry = try #require(try CompiledCatalog.entries()[key])
        #expect(entry.localizations?["en"]?.stringUnit?.value == key)
        #expect(entry.comment?.isEmpty == false)
    }

    @Test(arguments: ["en", "ru"])
    func theCitationBreaksOnlyAfterEtAlInEveryLanguage(language: String) throws {
        let entries = try CompiledCatalog.entries()
        let keys = entries.keys.filter { $0.contains("Garrett") && $0.contains("Each answer") }
        #expect(keys.count == 1)
        let value = try #require(keys.first.flatMap { entries[$0]?.localizations?[language]?.stringUnit?.value })
        #expect(value.hasSuffix("(Garrett\u{00A0}et\u{00A0}al., J\u{00A0}Rheumatol\u{00A0}1994)."))
    }
}
