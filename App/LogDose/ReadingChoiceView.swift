// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The readings a dose can point at, newest first, with a check mark on the one in use. It has no choice of no
/// reading: a dose without one is logged from the "Log how you feel now" row on Log Dose.
struct ReadingChoiceView: View {
    let entries: [Entry]
    let model: EntryLogModel
    let chosenID: UUID?
    let onPick: (Entry) -> Void
    let onAdded: (Entry) -> Void
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingNewEntry = false
    /// New Entry reports its save before it closes, and the choice closes only after New Entry is gone.
    @State private var addedEntry: Entry?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(entries) { entry in
                        choiceRow(entry)
                    }
                }
                Section {
                    Button("Log how you feel now") {
                        isShowingNewEntry = true
                    }
                    .accessibilityIdentifier("reading-log-new")
                }
            }
            .navigationTitle("Choose an entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("reading-cancel")
                }
            }
            .sheet(isPresented: $isShowingNewEntry, onDismiss: finishAdding) {
                NewEntryView(model: model, onSaved: onSaved, onAdded: { addedEntry = $0 })
            }
        }
    }

    private func choiceRow(_ entry: Entry) -> some View {
        let isChecked = entry.id == chosenID
        return Button {
            onPick(entry)
            dismiss()
        } label: {
            HStack {
                EntryIconRow(entry: entry)
                    .spokenAsReading()
                if isChecked {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(EntryIconRow.spokenKind(of: entry))
        .accessibilityValue(EntryIconRow.readingOptionValue(for: entry))
        .accessibilityIdentifier("reading-option")
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    private func finishAdding() {
        guard let saved = addedEntry else { return }
        addedEntry = nil
        onAdded(saved)
        dismiss()
    }
}
