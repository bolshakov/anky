// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The readings a dose can point at, newest first, with a check mark on the one in use. It is pushed from the form's
/// Before this dose row. A caller that passes `onPickNone` gets a first card with None, ticked while `isNoneChosen`.
struct ReadingChoiceView: View {
    let entries: [Entry]
    let model: EntryLogModel
    let chosenID: UUID?
    let doseAt: Date
    var isNoneChosen = false
    var onPickNone: (() -> Void)?
    let onPick: (Entry) -> Void
    let onAdded: (Entry) -> Void
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newEntry: DoseEntryRequest?
    /// New Entry reports its save before it closes, and the choice goes back only after New Entry is gone.
    @State private var addedEntry: Entry?

    var body: some View {
        List {
            if let onPickNone {
                CardSection(id: "reading-choices-none") {
                    TintRow(Text("None"), isSelected: isNoneChosen) {
                        onPickNone()
                        dismiss()
                    }
                    .accessibilityIdentifier("reading-none")
                }
            }
            CardSection(id: "reading-choices") {
                ForEach(ReadingLink.choices(in: entries, chosen: chosenID, at: doseAt)) { entry in
                    choiceRow(entry)
                }
            }
            CardSection(id: "reading-new") {
                Button {
                    newEntry = DoseEntryRequest(doseAt: doseAt)
                } label: {
                    ReadingPromptText(prompt: .forDose(at: doseAt, now: .now))
                }
                .accessibilityIdentifier("reading-log-new")
            }
        }
        .screenSpacing()
        .lastBlockClearance()
        .navigationTitle("Choose an Entry")
        .navigationBarTitleDisplayMode(.inline)
        .doseEntrySheet(
            $newEntry,
            model: model,
            onDismiss: finishAdding,
            onSaved: onSaved,
            onAdded: { addedEntry = $0 }
        )
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
                        .foregroundStyle(Color.tint)
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
