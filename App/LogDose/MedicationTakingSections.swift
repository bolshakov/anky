// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationTakingSections: View {
    @Binding var draft: MedicationDraft

    var body: some View {
        Section {
            TakenAsControl(takenAs: $draft.takenAs)
                .listRowBackground(Color.clear)
        } header: {
            Text("How you take it")
                .font(.footnote)
                .accessibilityAddTraits(.isHeader)
        }

        Section {
            CheckInDelayMenu(checkInAfter: $draft.checkInAfter)
        } header: {
            Text("Check in after a dose")
                .font(.footnote)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("Anky asks how your pain is after this long. Off until you choose a time.")
                .font(.footnote)
        }
    }
}
