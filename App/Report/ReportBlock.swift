// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A piece of the report's content. A whole block stays on one page.
enum ReportBlock {
    case whole(AnyView)
}
