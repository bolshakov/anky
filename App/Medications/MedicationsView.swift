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
        .sensoryFeedback(.success, trigger: saveTicks)
        .medicationFailureAlert($failure)
        .onAppear { medications.reload() }
        .listSectionSpacing(.custom(12))
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Add medication") {
                isShowingNewMedication = true
            }
            .buttonStyle(PinnedButtonStyle())
            .accessibilityIdentifier("medications-add")
            .padding()
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
            Section {
                ForEach(active) { medication in
                    Button {
                        editing = medication
                    } label: {
                        MedicationRow(medication: medication)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("medication-row")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Archive", systemImage: "archivebox") {
                            archive(medication)
                        }
                        .tint(.accentColor)
                    }
                }
            } footer: {
                if medications.archivedCount == 0 {
                    archiveFootnote
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

    private var archiveFootnote: some View {
        MedicationsFootnote(
            text: "Swipe left to archive. Archived medications leave Log Dose; doses you logged stay in History."
        )
    }

    @ViewBuilder
    private var archivedSection: some View {
        if medications.archivedCount > 0 {
            Section {
                NavigationLink {
                    ArchivedView(medications: medications)
                } label: {
                    ArchivedCard(count: medications.archivedCount)
                }
            } footer: {
                if !active.isEmpty {
                    archiveFootnote
                }
            }
        }
    }

    @ViewBuilder
    private var emptySection: some View {
        if active.isEmpty {
            Section {
                MedicationsEmptyBlock()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listSectionSpacing(.custom(96))
        }
    }
}
