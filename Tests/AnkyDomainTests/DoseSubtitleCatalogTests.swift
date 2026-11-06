// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct DoseSubtitleCatalogTests {
    @Test func theBeforeSubtitleIsOneWholeKeyPerKind() throws {
        let keys = try CompiledCatalog.entries().keys
        for kind in ["pain", "stiffness", "fatigue"] {
            #expect(keys.contains("Dose · \(kind) was %lld"), "no whole key for \(kind)")
            #expect(!keys.contains("\(kind) was %lld"), "the short \(kind) key is still in the catalog")
        }
    }
}
