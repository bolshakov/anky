// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A piece of the report's content. A whole block stays on one page. A table splits between its rows.
enum ReportBlock {
    case whole(AnyView)
    case table(rows: [ReportMedicationRowText], hasScheduled: Bool)
    case basdai(rows: [ReportBasdaiRowText])
}
