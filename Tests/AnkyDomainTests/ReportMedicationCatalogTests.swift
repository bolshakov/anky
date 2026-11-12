// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct ReportMedicationCatalogTests {
    private static let keys = """
    Medication: doses, and pain before and after
    Medication, continued
    Doses
    Per week
    With an after-reading
    Pain before: average (lowest–highest)
    Pain after: average (lowest–highest)
    Average time to after-reading
    """.split(separator: "\n").map(String.init)

    @Test(arguments: keys)
    func theMedicationBlockStringReadsAsItsKeyInEnglishWithAComment(key: String) throws {
        let entry = try #require(try CompiledCatalog.entries()[key])
        #expect(entry.localizations?["en"]?.stringUnit?.value == key)
        #expect(entry.comment?.isEmpty == false)
    }
}
