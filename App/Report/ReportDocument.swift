// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The report's blocks laid out on pages, with the totals band first on page 1.
@MainActor struct ReportDocument {
    let size: ReportPageSize
    let headerLine: String
    let totals: ReportTotalsText
    let blocks: [ReportBlock]

    var pages: [ReportPage] {
        [ReportPage(size: size, headerLine: headerLine, pageNumber: 1, pageCount: 1, content: AnyView(firstPage))]
    }

    private var firstPage: some View {
        VStack(alignment: .leading, spacing: ReportMetrics.sectionGap) {
            ReportTotalsBand(totals: totals)
            ForEach(blocks.indices, id: \.self) { index in
                blocks[index].view
            }
        }
    }
}

private extension ReportBlock {
    var view: AnyView {
        switch self {
        case let .whole(view): view
        }
    }
}
