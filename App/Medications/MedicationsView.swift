// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationsView: View {
    let medications: MedicationsModel
    @State private var isShowingNewMedication = false

    var body: some View {
        List {
            activeSection
            archivedSection
            emptySection
        }
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
            MedicationFormView(medications: medications, onSaved: {})
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
                    MedicationRow(medication: medication)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Archive", systemImage: "archivebox") {
                                try? medications.archive(id: medication.id)
                            }
                        }
                }
            } footer: {
                if medications.archivedCount == 0 {
                    MedicationsFootnote()
                }
            }
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if medications.archivedCount > 0 {
            Section {
                ArchivedCard(count: medications.archivedCount)
            } footer: {
                if !active.isEmpty {
                    MedicationsFootnote()
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
