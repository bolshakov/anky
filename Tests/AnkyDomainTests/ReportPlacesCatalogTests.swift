// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct ReportPlacesCatalogTests {
    private static let keys = ["Places logged", "Place", "Entries", "None logged in this period"]

    @Test(arguments: keys)
    func thePlacesBlockStringReadsAsItsKeyInEnglishWithAComment(key: String) throws {
        let entry = try #require(try CompiledCatalog.entries()[key])
        #expect(entry.localizations?["en"]?.stringUnit?.value == key)
        #expect(entry.comment?.isEmpty == false)
    }
}
