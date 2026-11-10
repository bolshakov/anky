// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct ArchivedView: View {
    let medications: MedicationsModel
    let onRestored: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Medication?
    @State private var successTicks = 0
    @State private var failure: MedicationFailure?

    var body: some View {
        List {
            CardSection(
                footnote: Text("Swipe left to restore. Doses you logged stay in History."),
                id: "archived"
            ) {
                ForEach(medications.archived) { medication in
                    Button {
                        editing = medication
                    } label: {
                        TwoLineRow(Text(medication.listTitle), subtitle: Text(medication.takenAs.title))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityRepresentation {
                        Button { editing = medication } label: { Color.clear }
                            .accessibilityLabel(medication.spokenRowLabel)
                            .accessibilityIdentifier("archived-row")
                    }
                    .fillsCardRow()
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Restore", systemImage: "arrow.counterclockwise") {
                            restore(medication)
                        }
                        .tint(.accentColor)
                    }
                }
            }
        }
        .screenSpacing()
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: successTicks)
        .medicationFailureAlert($failure)
        .onChange(of: medications.archived.isEmpty) {
            if medications.archived.isEmpty {
                dismiss()
            }
        }
        .sheet(item: $editing) { medication in
            MedicationFormView(
                medications: medications,
                editing: medication,
                onSaved: { _ in successTicks += 1 },
                onArchivedOrRestored: restored
            )
        }
    }

    private func restore(_ medication: Medication) {
        do {
            try medications.restore(id: medication.id)
            restored()
        } catch {
            failure = .restore
        }
    }

    /// The last restore closes this screen, so its haptic belongs to the screen underneath.
    private func restored() {
        if medications.archived.isEmpty {
            onRestored()
        } else {
            successTicks += 1
        }
    }
}
