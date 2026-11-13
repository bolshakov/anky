// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct RussianToneCatalogTests {
    @Test func noRussianValueAddressesTheReaderWithVy() throws {
        let entries = try CompiledCatalog.entries()
        let formalAddress = try Regex("вы |ваш").ignoresCase()
        for key in entries.keys.sorted() {
            let units = entries[key]?.localizations?["ru"]?.stringUnits ?? []
            for unit in units {
                #expect(
                    unit.value.firstMatch(of: formalAddress) == nil,
                    "\(key) addresses the reader with вы or ваш: \(unit.value)"
                )
            }
        }
    }
}
