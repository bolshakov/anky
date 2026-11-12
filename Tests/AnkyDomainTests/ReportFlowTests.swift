// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct ReportFlowTests {
    private func whole(_ block: Int) -> ReportFlowSlice {
        ReportFlowSlice(block: block, rows: nil, isContinued: false, showsNote: false)
    }

    private func table(
        _ block: Int, _ rows: Range<Int>, continued: Bool = false, note: Bool = false
    ) -> ReportFlowSlice {
        ReportFlowSlice(block: block, rows: rows, isContinued: continued, showsNote: note)
    }

    private func tableBlock(rows: [Double]) -> ReportFlowBlock {
        .table(heading: 10, columnHeader: 10, rows: rows, note: 10)
    }

    private func pages(_ blocks: [ReportFlowBlock], gap: Double = 10, page: Double = 100) -> [[ReportFlowSlice]] {
        ReportFlow.pages(blocks: blocks, gap: gap, firstPage: page, laterPages: page)
    }

    @Test func noBlocksGiveOnePage() {
        #expect(pages([]) == [[]])
    }

    @Test func blocksThatFitExactlyShareAPage() {
        #expect(pages([.whole(height: 45), .whole(height: 45)]) == [[whole(0), whole(1)]])
    }

    @Test func aBlockMovesWholeToTheNextPage() {
        #expect(pages([.whole(height: 45), .whole(height: 46)]) == [[whole(0)], [whole(1)]])
    }

    @Test func theGapIsNotAddedAtTheTopOfAPage() {
        let blocks: [ReportFlowBlock] = [.whole(height: 95), .whole(height: 50), .whole(height: 40)]
        #expect(pages(blocks) == [[whole(0)], [whole(1), whole(2)]])
    }

    @Test func laterPagesHaveTheirOwnRoom() {
        let blocks: [ReportFlowBlock] = [.whole(height: 100), .whole(height: 90), .whole(height: 100)]
        let result = ReportFlow.pages(blocks: blocks, gap: 10, firstPage: 100, laterPages: 200)
        #expect(result == [[whole(0)], [whole(1), whole(2)]])
    }

    @Test func aTableSplitsBetweenRows() {
        let blocks: [ReportFlowBlock] = [.whole(height: 30), tableBlock(rows: [20, 20, 20, 20])]
        #expect(pages(blocks) == [[whole(0), table(1, 0 ..< 2)], [table(1, 2 ..< 4, continued: true, note: true)]])
    }

    @Test func aHeadingIsNotAloneAtAPageBottom() {
        let blocks: [ReportFlowBlock] = [.whole(height: 60), tableBlock(rows: [20, 20])]
        #expect(pages(blocks) == [[whole(0)], [table(1, 0 ..< 2, note: true)]])
    }

    @Test func aNoteIsNotAloneSoTheLastRowMovesWithIt() {
        let blocks: [ReportFlowBlock] = [tableBlock(rows: [20, 20, 20, 20])]
        #expect(pages(blocks) == [[table(0, 0 ..< 3)], [table(0, 3 ..< 4, continued: true, note: true)]])
    }

    @Test func aNoteIsNotAloneSoATableWithOneRowMovesWhole() {
        let blocks: [ReportFlowBlock] = [.whole(height: 50), tableBlock(rows: [20])]
        #expect(pages(blocks) == [[whole(0)], [table(1, 0 ..< 1, note: true)]])
    }

    @Test func aBlockTallerThanAPageSitsAlone() {
        let blocks: [ReportFlowBlock] = [.whole(height: 30), .whole(height: 150), .whole(height: 0)]
        #expect(pages(blocks) == [[whole(0)], [whole(1)], [whole(2)]])
    }

    @Test func aRowTallerThanAPageSitsAloneAndPackingGoesOn() {
        let blocks: [ReportFlowBlock] = [tableBlock(rows: [20, 150, 20]), .whole(height: 20)]
        let tall = table(0, 1 ..< 2, continued: true)
        let last = table(0, 2 ..< 3, continued: true, note: true)
        #expect(pages(blocks) == [[table(0, 0 ..< 1)], [tall], [last, whole(1)]])
    }

    @Test func aLastRowAndNoteTallerThanAPageSitAloneTogether() {
        let blocks: [ReportFlowBlock] = [tableBlock(rows: [75]), .whole(height: 10)]
        #expect(pages(blocks, gap: 0) == [[table(0, 0 ..< 1, note: true)], [whole(1)]])
    }

    @Test func aTableWithNoRowsKeepsItsHeadingWithItsNote() {
        let blocks: [ReportFlowBlock] = [.whole(height: 70), tableBlock(rows: [])]
        #expect(pages(blocks) == [[whole(0)], [table(1, 0 ..< 0, note: true)]])
    }

    @Test func aContinuedTablesSlicesCoverEveryRowOnceInOrder() throws {
        let rows = (0 ..< 50).map { Double(10 + $0 % 7) }
        let medication = ReportFlowBlock.table(heading: 12, columnHeader: 8, rows: rows, note: 15)
        let blocks: [ReportFlowBlock] = [.whole(height: 40), medication, .whole(height: 30)]
        let slices = pages(blocks, gap: 6, page: 120).flatMap(\.self).filter { $0.block == 1 }

        try #require(slices.count > 2)
        #expect(slices.flatMap { Array($0.rows ?? 0 ..< 0) } == Array(0 ..< 50))
        #expect(slices.map(\.isContinued) == [false] + Array(repeating: true, count: slices.count - 1))
        #expect(slices.map(\.showsNote) == Array(repeating: false, count: slices.count - 1) + [true])
    }
}
