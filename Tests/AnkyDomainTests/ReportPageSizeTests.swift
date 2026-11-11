// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportPageSizeTests {
    @Test(arguments: ["US", "CA"])
    func northAmericaGetsUSLetter(region: String) {
        let size = ReportPageSize.forRegion(Locale.Region(region))
        #expect(size.width == 612)
        #expect(size.height == 792)
    }

    @Test func germanyGetsA4() {
        let size = ReportPageSize.forRegion(Locale.Region("DE"))
        #expect(size.width == 595.2)
        #expect(size.height == 841.8)
    }

    @Test func noRegionGetsA4() {
        #expect(ReportPageSize.forRegion(nil) == ReportPageSize.forRegion(Locale.Region("DE")))
    }
}
