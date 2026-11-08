// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct CheckInBannerCatalogTests {
    @Test func theTakenLineIsOneKeyThatTakesTheSystemFormattedWhen() throws {
        let taken = try CompiledCatalog.entries().keys.filter { $0.hasPrefix("Taken") }
        #expect(taken == ["Taken %@."])
    }

    @Test func theBeforeReadingIsOneKeyPerKindThatTakesOnlyTheLevel() throws {
        let before = try CompiledCatalog.entries().keys.filter { $0.hasPrefix("Before:") }
        #expect(before.sorted() == ["Before: fatigue %lld.", "Before: pain %lld.", "Before: stiffness %lld."])
        for key in before {
            #expect(key.components(separatedBy: "%").count - 1 == 1, "\(key) takes another argument")
            #expect(key.contains("%lld"), "\(key) takes no level")
        }
    }
}
