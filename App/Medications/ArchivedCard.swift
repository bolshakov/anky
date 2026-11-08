// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ArchivedCard: View {
    let count: Int

    var body: some View {
        ValueRow(Text("Archived"), value: Text("\(count)"))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Archived"))
            .accessibilityValue("\(count)")
            .accessibilityIdentifier("archived-card")
    }
}
