// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationTakingSections: View {
    @Binding var draft: MedicationDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Section {
            if dynamicTypeSize.isAccessibilitySize {
                takenAsPicker
                    .pickerStyle(.menu)
            } else {
                takenAsPicker
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
            }
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

    private var takenAsPicker: some View {
        Picker("How you take it", selection: $draft.takenAs) {
            ForEach(TakenAs.allCases, id: \.self) { option in
                Text(option.title).tag(option)
            }
        }
        .labelsHidden()
        .accessibilityIdentifier("taken-as")
    }
}
