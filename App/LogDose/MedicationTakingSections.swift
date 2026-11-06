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

        DoseCheckInSection(checkIn: $draft.checkIn, readingKind: nil)
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
