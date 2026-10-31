// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct LogDoseView: View {
    let medications: MedicationsModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var isShowingNewMedication = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    if active.isEmpty {
                        Text("No medications yet")
                            .accessibilityIdentifier("dose-no-medications")
                    }
                    ForEach(active) { medication in
                        medicationRow(medication)
                    }
                    Button("Add medication") {
                        isShowingNewMedication = true
                    }
                    .accessibilityIdentifier("dose-add-medication")
                }
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("log-dose-cancel")
                }
            }
            .sheet(isPresented: $isShowingNewMedication) {
                MedicationFormView(medications: medications, onSaved: medicationSaved)
            }
            .sensoryFeedback(.selection, trigger: selectionTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
        }
    }

    private var active: [Medication] {
        medications.active
    }

    /// The row the person last chose, or the first active row while none is chosen or the chosen one has gone.
    private var checkedID: UUID? {
        if let selectedID, active.contains(where: { $0.id == selectedID }) {
            return selectedID
        }
        return active.first?.id
    }

    private func medicationRow(_ medication: Medication) -> some View {
        let isChecked = medication.id == checkedID
        return Button {
            select(medication)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(medication.listTitle)
                        .fontWeight(isChecked ? .semibold : .regular)
                    Text(medication.takenAs.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isChecked {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dose-medication-row")
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    private func select(_ medication: Medication) {
        guard medication.id != checkedID else { return }
        selectedID = medication.id
        selectionTicks += 1
    }

    /// The new medication is the newest, so it is last in the active list and becomes the chosen row. Choosing it
    /// does not tick, because the success haptic plays instead.
    private func medicationSaved() {
        selectedID = active.last?.id
        saveTicks += 1
    }
}
