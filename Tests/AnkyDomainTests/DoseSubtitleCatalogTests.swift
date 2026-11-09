// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseSubtitleCatalogTests {
    @Test func theBeforePhraseIsOneWholeKeyPerKindWithoutTheDoseWord() throws {
        let keys = try CompiledCatalog.entries().keys
        for kind in ["pain", "stiffness", "fatigue"] {
            #expect(keys.contains("\(kind) was %lld"), "no whole key for \(kind)")
            #expect(!keys.contains("Dose · \(kind) was %lld"), "the dose word is still in the \(kind) key")
        }
    }

    @Test func noKeyHoldsTheSecondLinesSeparator() throws {
        let joined = try CompiledCatalog.entries().keys.filter { $0.contains(RowSecondLine.separator) }
        #expect(joined.sorted() == ["After · checked in at %@", "Done · %lld places"])
    }

    @Test func noKeyIsABareJoinOfTwoValues() throws {
        let keys = try CompiledCatalog.entries().keys
        #expect(!keys.contains("%@ %@"))
        #expect(!keys.contains("%@, %@"))
    }
}
