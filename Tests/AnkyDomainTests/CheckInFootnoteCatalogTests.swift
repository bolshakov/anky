// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct CheckInFootnoteCatalogTests {
    private let footnotes = Set("""
    Anky asks how you feel after this long.
    Anky asks how you feel after this long. Turn it on to choose a time.
    Anky asks how your pain is after this long.
    Anky asks how your pain is after this long. Turn it on to choose a time.
    Anky asks how stiff you are after this long.
    Anky asks how stiff you are after this long. Turn it on to choose a time.
    Anky asks how tired you are after this long.
    Anky asks how tired you are after this long. Turn it on to choose a time.
    """.split(separator: "\n").map(String.init))

    @Test func theFootnoteKeysAreExactlyTheEightWholeSentencesWithNoFormatSpecifier() throws {
        let keys = try CompiledCatalog.entries().keys
        let found = Set(keys.filter { $0.contains("after this long") || $0.contains("choose a time") })
        #expect(found == footnotes)
        #expect(found.filter { $0.contains("%") }.isEmpty)
    }

    @Test func noKeyNamesTheMedicationTheDoseIsSavedFor() throws {
        let keys = try CompiledCatalog.entries().keys
        #expect(keys.filter { $0.contains("Saved for") }.isEmpty)
    }
}
