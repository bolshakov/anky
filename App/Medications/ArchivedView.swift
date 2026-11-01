// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct ArchivedView: View {
    let medications: MedicationsModel
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Medication?
    @State private var saveTicks = 0
    @State private var failure: MedicationFailure?

    var body: some View {
        List {
            Section {
                ForEach(medications.archived) { medication in
                    Button {
                        editing = medication
                    } label: {
                        MedicationRow(medication: medication, showsChevron: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("archived-row")
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Restore", systemImage: "arrow.counterclockwise") {
                            restore(medication)
                        }
                        .tint(.accentColor)
                    }
                }
            } footer: {
                MedicationsFootnote(text: "Swipe left to restore. Doses you logged stay in History.")
            }
        }
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: saveTicks)
        .medicationFailureAlert($failure)
        .onChange(of: medications.archived.isEmpty) {
            if medications.archived.isEmpty {
                dismiss()
            }
        }
        .sheet(item: $editing) { medication in
            MedicationFormView(medications: medications, editing: medication, onSaved: { saveTicks += 1 })
        }
    }

    private func restore(_ medication: Medication) {
        do {
            try medications.restore(id: medication.id)
        } catch {
            failure = .restore
        }
    }
}
