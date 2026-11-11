// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct CSVTableTests {
    private func text(of cell: CSVCell) -> String {
        CSVTable(header: ["a"], rows: [[cell]]).text
    }

    @Test func writesTheHeaderBareAndEndsEveryLineWithANewline() {
        let table = CSVTable(header: ["id", "note"], rows: [[.number(1), .text("x")], [.number(2), .text("y")]])
        #expect(table.text == "id,note\n1,\"x\"\n2,\"y\"\n")
    }

    @Test func writesOnlyTheHeaderWhenThereAreNoRows() {
        #expect(CSVTable(header: ["id", "time"], rows: []).text == "id,time\n")
    }

    @Test func quotesATextCellEvenWithoutAComma() {
        #expect(text(of: .text("plain")) == "a\n\"plain\"\n")
    }

    @Test func quotesAnEmptyText() {
        #expect(text(of: .text("")) == "a\n\"\"\n")
    }

    @Test func doublesAQuoteInsideAText() {
        #expect(text(of: .text("Hurt, \"a lot\"")) == "a\n\"Hurt, \"\"a lot\"\"\"\n")
    }

    @Test(arguments: ["one\ntwo", "one\r\ntwo", "one\rtwo"])
    func keepsALineBreakInsideTheQuotesAsItIs(note: String) {
        #expect(text(of: .text(note)) == "a\n\"\(note)\"\n")
    }

    @Test func writesNumberAndEmptyCellsBare() {
        let table = CSVTable(header: ["a", "b", "c"], rows: [[.number(-3), .empty, .number(10)]])
        #expect(table.text == "a,b,c\n-3,,10\n")
    }

    @Test func keepsLettersBeyondASCIIAndWritesNoByteOrderMark() {
        let table = CSVTable(header: ["note"], rows: [[.text("Tëma Бехтерев")]])
        #expect(table.text == "note\n\"Tëma Бехтерев\"\n")
        #expect(Array(Data(table.text.utf8).prefix(3)) == Array("not".utf8))
    }
}
