// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct MedicationFormView: View {
    let medications: MedicationsModel
    let editing: Medication?
    let onSaved: (Medication.ID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MedicationDraft
    // Made once per opening, so a retry after a failed save writes the same medication.
    @State private var saver = MedicationSave(id: UUID())
    @State private var isSaved = false
    @State private var failure: MedicationFailure?
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, strength
    }

    init(medications: MedicationsModel, editing: Medication? = nil, onSaved: @escaping (Medication.ID) -> Void) {
        self.medications = medications
        self.editing = editing
        self.onSaved = onSaved
        _draft = State(initialValue: editing.map(MedicationDraft.init) ?? MedicationDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                CardSection(id: "medication-fields") {
                    TextField("Name", text: $draft.name)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .strength }
                        .rowHeight()
                        .contentShape(Rectangle())
                        .onTapGesture { focus = .name }
                        .accessibilityLabel("Name")
                        .accessibilityIdentifier("medication-name")
                    TextField("Strength, for example 500 mg", text: $draft.strength)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .strength)
                        .submitLabel(.done)
                        .onSubmit { focus = nil }
                        .rowHeight()
                        .contentShape(Rectangle())
                        .onTapGesture { focus = .strength }
                        .accessibilityLabel("Strength, optional")
                        .accessibilityIdentifier("medication-strength")
                }
                MedicationTakingSections(draft: $draft)
            }
            .screenSpacing()
            .accessibilityIdentifier("medication-form")
            .navigationTitle(editing == nil ? "New Medication" : "Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: Spacing.rowMinimumHeight)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("medication-cancel")
                }
                if let editing {
                    ToolbarItem(placement: .primaryAction) {
                        MedicationMoreMenu(
                            isArchived: editing.archivedAt != nil,
                            onArchive: { archive(editing) },
                            onRestore: { restore(editing) }
                        )
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .primaryButton()
                .controlSize(.large)
                .disabled(!draft.isSavable)
                .accessibilityIdentifier("medication-save")
                .padding(.horizontal, Spacing.screenMargin)
                .padding(.vertical, Spacing.bottomClearance)
                .background(Color.surface)
            }
            .medicationFailureAlert($failure)
        }
    }

    private func save() {
        do {
            guard try writeDraft() else { return }
        } catch {
            failure = .save
            return
        }
        onSaved(editing?.id ?? saver.id)
        dismiss()
    }

    /// Returns false when this opening has already saved, so a second tap writes nothing.
    private func writeDraft() throws -> Bool {
        guard let editing else {
            return try saver.save(draft, at: .now, add: medications.add)
        }
        guard !isSaved else { return false }
        try medications.update(draft.applied(to: editing, at: .now))
        isSaved = true
        return true
    }

    /// Archive and restore are not saves, so they close the form without calling `onSaved`.
    private func archive(_ medication: Medication) {
        do {
            try medications.archive(id: medication.id)
        } catch {
            failure = .archive
            return
        }
        dismiss()
    }

    private func restore(_ medication: Medication) {
        do {
            try medications.restore(id: medication.id)
        } catch {
            failure = .restore
            return
        }
        dismiss()
    }
}
