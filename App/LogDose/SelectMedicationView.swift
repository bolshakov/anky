// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

/// Pushed from the Medication row of a dose form. A tap on a row selects it and goes back, and the system back button
/// goes back with the selection kept. With `onAdded` set, an Add medication card below the list opens the New
/// Medication sheet, and the medication it saves is handed on before the screen goes back.
struct SelectMedicationView: View {
    let medications: MedicationsModel
    let choices: [Medication]
    let selectedID: UUID?
    let onSelect: (Medication) -> Void
    let onAdded: ((Medication.ID) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingNewMedication = false

    var body: some View {
        Form {
            CardSection(id: "select-medication") {
                ForEach(choices) { medication in
                    TintRow(
                        Text(verbatim: medication.listTitle),
                        value: Text(medication.takenAs.title),
                        isSelected: medication.id == selectedID
                    ) {
                        onSelect(medication)
                        dismiss()
                    }
                    .accessibilityIdentifier("dose-medication-row")
                }
            }
            if onAdded != nil {
                CardSection(id: "add-medication") {
                    Button("Add medication") {
                        isShowingNewMedication = true
                    }
                    .rowHeight()
                    .accessibilityIdentifier("dose-add-medication")
                }
            }
        }
        .screenSpacing()
        .lastBlockClearance()
        .navigationTitle("Select medication")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingNewMedication) {
            MedicationFormView(medications: medications, onSaved: medicationSaved)
        }
    }

    private func medicationSaved(_ id: Medication.ID) {
        onAdded?(id)
        dismiss()
    }
}
