// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationTakingSections: View {
    @Binding var draft: MedicationDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CardSection(Text("How you take it"), id: "taking") {
            if dynamicTypeSize.isAccessibilitySize {
                MenuRow(Text("How you take it"), selection: $draft.takenAs) { options }
                    .accessibilityLabel("How you take it")
                    .accessibilityValue(Text(draft.takenAs.title))
                    .accessibilityIdentifier("taken-as")
            } else {
                Picker("How you take it", selection: $draft.takenAs) { options }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("taken-as")
                    .nonCardBlock()
            }
        }
        MedicationCheckInSection(checkIn: $draft.checkIn)
    }

    private var options: some View {
        ForEach(TakenAs.allCases, id: \.self) { option in
            Text(option.title).tag(option)
        }
    }
}
