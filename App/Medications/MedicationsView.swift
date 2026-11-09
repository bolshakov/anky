// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct MedicationsView: View {
    let medications: MedicationsModel
    @State private var isShowingNewMedication = false
    @State private var editing: Medication?
    @State private var saveTicks = 0
    @State private var failure: MedicationFailure?

    var body: some View {
        List {
            activeSection
            archivedSection
            emptySection
        }
        .screenSpacing()
        .sensoryFeedback(.success, trigger: saveTicks)
        .medicationFailureAlert($failure)
        .onAppear { medications.reload() }
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .bottomPrimaryButton(Text("Add medication"), id: "medications-add") {
            isShowingNewMedication = true
        }
        .sheet(isPresented: $isShowingNewMedication) {
            MedicationFormView(medications: medications, onSaved: { saveTicks += 1 })
        }
        .sheet(item: $editing) { medication in
            MedicationFormView(medications: medications, editing: medication, onSaved: { saveTicks += 1 })
        }
    }

    private var active: [Medication] {
        medications.active
    }

    @ViewBuilder
    private var activeSection: some View {
        if !active.isEmpty {
            CardSection(footnote: archiveFootnote, id: "medications") {
                ForEach(active) { medication in
                    TwoLineRow(
                        Text(medication.listTitle),
                        subtitle: Text(medication.takenAs.title)
                    ) {
                        editing = medication
                    }
                    .accessibilityIdentifier("medication-row")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Archive", systemImage: "archivebox") {
                            archive(medication)
                        }
                        .tint(.accentColor)
                    }
                }
            }
        }
    }

    private func archive(_ medication: Medication) {
        do {
            try medications.archive(id: medication.id)
        } catch {
            failure = .archive
        }
    }

    private var archiveFootnote: Text {
        Text("Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History.")
    }

    @ViewBuilder
    private var archivedSection: some View {
        if medications.archivedCount > 0 {
            CardSection(id: "archived-link") {
                NavigationLink {
                    ArchivedView(medications: medications)
                } label: {
                    ArchivedCard(count: medications.archivedCount)
                }
                .fillsCardRow()
            }
        }
    }

    @ViewBuilder
    private var emptySection: some View {
        if active.isEmpty {
            Section {
                MedicationsEmptyBlock()
                    .nonCardBlock()
            }
            .emptyBlockGap()
        }
    }
}
