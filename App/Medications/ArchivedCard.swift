// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ArchivedCard: View {
    let count: Int

    var body: some View {
        HStack {
            Text("Archived")
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Archived"))
        .accessibilityValue("\(count)")
        .accessibilityIdentifier("archived-card")
    }
}
