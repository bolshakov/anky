// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct RowSecondLineTests {
    @Test func theTimeAndTheDetailAreJoinedWithADot() {
        #expect(RowSecondLine.text(time: "08:42", detail: "Lower back") == "08:42 · Lower back")
    }

    @Test func aMissingDetailLeavesTheTimeAlone() {
        #expect(RowSecondLine.text(time: "08:42", detail: nil) == "08:42")
    }

    @Test func anEmptyDetailLeavesTheTimeAlone() {
        #expect(RowSecondLine.text(time: "08:42", detail: "") == "08:42")
    }

    @Test func aTwelveHourTimeKeepsItsNarrowSpaceBeforeTheMeridiem() {
        let time = "1:35\u{202F}AM"
        #expect(RowSecondLine.text(time: time, detail: "No place") == "1:35\u{202F}AM · No place")
    }
}
