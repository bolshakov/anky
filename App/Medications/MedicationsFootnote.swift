// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct MedicationsFootnote: View {
    var body: some View {
        Text("Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.leading, -16)
    }
}
