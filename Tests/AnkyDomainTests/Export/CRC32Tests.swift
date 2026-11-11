// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyDomain
import Foundation
import Testing

struct CRC32Tests {
    @Test func theCheckStringGivesTheStandardValue() {
        #expect(CRC32.checksum(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func emptyDataGivesZero() {
        #expect(CRC32.checksum(Data()) == 0)
    }

    @Test func aSliceIsReadFromItsOwnStart() {
        let whole = Data("xx123456789".utf8)
        #expect(CRC32.checksum(whole.dropFirst(2)) == 0xCBF4_3926)
    }
}
