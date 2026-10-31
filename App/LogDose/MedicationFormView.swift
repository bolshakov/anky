// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationFormView: View {
    let medications: MedicationsModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = MedicationDraft()
    // Made once per opening, so a retry after a failed save writes the same medication.
    @State private var medicationID = UUID()
    @State private var hasSaved = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, strength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .strength }
                        .accessibilityIdentifier("medication-name")
                    TextField("Strength, for example 500 mg", text: $draft.strength)
                        .focused($focus, equals: .strength)
                        .submitLabel(.done)
                        .onSubmit { focus = nil }
                        .accessibilityIdentifier("medication-strength")
                }
            }
            .navigationTitle("New Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("medication-cancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save medication") {
                    save()
                }
                .buttonStyle(PinnedButtonStyle())
                .disabled(!draft.isSavable)
                .accessibilityIdentifier("medication-save")
                .padding()
            }
        }
    }

    private func save() {
        guard !hasSaved else { return }
        do {
            try medications.add(draft.medication(id: medicationID, at: .now))
        } catch {
            return
        }
        hasSaved = true
        onSaved()
        dismiss()
    }
}
