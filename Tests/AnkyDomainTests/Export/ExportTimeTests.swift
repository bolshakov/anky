// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ExportTimeTests {
    @Test func writesAMomentInUTCWithAZ() {
        #expect(ExportTime.utc(Date(timeIntervalSince1970: 1_762_848_900)) == "2025-11-11T08:15:00Z")
    }

    @Test func dropsFractionalSeconds() {
        #expect(ExportTime.utc(Date(timeIntervalSince1970: 1_762_848_905.987)) == "2025-11-11T08:15:05Z")
    }
}
