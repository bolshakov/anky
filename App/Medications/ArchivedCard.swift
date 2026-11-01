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
        }
        .padding(.vertical, 8)
        .frame(minHeight: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Archived"))
        .accessibilityValue("\(count)")
        .accessibilityIdentifier("archived-card")
    }
}
