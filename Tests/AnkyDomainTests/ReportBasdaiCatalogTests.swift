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
    func theBasdaiBlockStringIsInTheCatalogWithAComment(key: String) throws {
        let entry = try #require(try CompiledCatalog.entries()[key])
        #expect(entry.comment?.isEmpty == false)
    }
}
