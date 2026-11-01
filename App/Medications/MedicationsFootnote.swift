// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct MedicationsFootnote: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.leading, -16)
    }
}
