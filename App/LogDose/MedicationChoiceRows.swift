// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

/// The rows of the Medication card on a dose form: one per choice, then Add medication, which opens the New Medication
/// sheet and hands on the medication it saves. With no choice the card says so above Add medication.
struct MedicationChoiceRows: View {
    let medications: MedicationsModel
    let choices: [Medication]
    let selectedID: UUID?
    let onSelect: (Medication) -> Void
    let onAdded: (Medication.ID) -> Void
    @State private var isShowingNewMedication = false

    var body: some View {
        if choices.isEmpty {
            Text("No medications yet")
                .accessibilityIdentifier("dose-no-medications")
        }
        ForEach(choices) { medication in
            TintRow(
                Text(verbatim: medication.listTitle),
                subtitle: Text(medication.takenAs.title),
                isSelected: medication.id == selectedID
            ) {
                onSelect(medication)
            }
            .accessibilityIdentifier("dose-medication-row")
        }
        Button("Add medication") {
            isShowingNewMedication = true
        }
        .rowHeight()
        .accessibilityIdentifier("dose-add-medication")
        .sheet(isPresented: $isShowingNewMedication) {
            MedicationFormView(medications: medications, onSaved: onAdded)
        }
    }
}
