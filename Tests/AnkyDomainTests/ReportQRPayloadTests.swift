// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct ReportQRPayloadTests {
    @Test func encodesTheAnkySite() {
        #expect(ReportQRPayload.url == "https://anky.bolshakov.dev")
    }

    @Test func labelNamesTheSiteWithoutTheScheme() {
        #expect(ReportQRPayload.label == "QR code: anky.bolshakov.dev")
    }
}
