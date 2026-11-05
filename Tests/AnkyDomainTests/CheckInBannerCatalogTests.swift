// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

struct CheckInBannerCatalogTests {
    @Test func everyBannerKeyTakesOnlyTheWhenPartAndTheLevel() throws {
        let banner = try CompiledCatalog.entries().keys.filter { $0.hasPrefix("Taken") }
        #expect(banner.count == 12)
        for key in banner {
            let times = occurrences(of: "%@", in: key)
            let levels = occurrences(of: "%lld", in: key)
            #expect(times == 1, "\(key) takes \(times) time parts")
            #expect(levels <= 1, "\(key) takes \(levels) levels")
            #expect(occurrences(of: "%", in: key) == times + levels, "\(key) takes another argument")
        }
    }

    private func occurrences(of specifier: String, in text: String) -> Int {
        text.components(separatedBy: specifier).count - 1
    }
}
