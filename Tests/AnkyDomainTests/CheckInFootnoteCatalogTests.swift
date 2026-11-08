// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct CheckInFootnoteCatalogTests {
    private let settingsFootnotes = Set("""
    Anky will ask how you feel after this long.
    Turn it on to choose a time.
    """.split(separator: "\n").map(String.init))

    private let explanationFootnotes = Set("""
    Starts from your earlier entry. Change the level or places if they differ.
    Saved as a pain entry.
    Saved as a stiffness entry.
    Saved as a fatigue entry.
    """.split(separator: "\n").map(String.init))

    @Test func theSettingsFootnoteKeysAreTheTwoSentencesWithNoFormatSpecifier() throws {
        let keys = try CompiledCatalog.entries().keys
        let found = Set(keys.filter { $0.contains("after this long") || $0.contains("choose a time") })
        #expect(found == settingsFootnotes)
        #expect(found.filter { $0.contains("%") }.isEmpty)
    }

    @Test func theExplanationFootnoteKeysAreTheEarlierEntrySentenceAndThreeLowercaseKindLines() throws {
        let keys = try CompiledCatalog.entries().keys
        let found = Set(keys.filter { $0.contains("Saved as a") || $0.contains("earlier") })
        #expect(found == explanationFootnotes)
        #expect(found.filter { $0.contains("%") }.isEmpty)
    }

    @Test func noKeyNamesTheMedicationTheDoseIsSavedFor() throws {
        let keys = try CompiledCatalog.entries().keys
        #expect(keys.filter { $0.contains("Saved for") }.isEmpty)
    }
}
