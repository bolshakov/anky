// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct RowChevron: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.ink2)
            .accessibilityHidden(true)
    }
}
