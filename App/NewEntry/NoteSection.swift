// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI
import UIKit

struct NoteSection: View {
    @Binding var draft: EntryDraft
    @FocusState private var isFocused: Bool
    @State private var note: String
    private static let textDidChange = NotificationCenter.default
        .publisher(for: UITextView.textDidChangeNotification)

    init(draft: Binding<EntryDraft>) {
        _draft = draft
        _note = State(initialValue: draft.wrappedValue.note)
    }

    var body: some View {
        CardSection(footnote: draft.noteCounter.map { Text(counterText($0)) }, id: "note") {
            TextField("Add a note", text: $note, axis: .vertical)
                .font(.body)
                .focused($isFocused)
                .accessibilityLabel("Note")
                .accessibilityIdentifier("note-field")
                .frame(maxWidth: .infinity, alignment: .leading)
                .rowHeight()
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused = true }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("note-card")
                .onChange(of: note) { _, typed in
                    draft.note = String(typed.prefix(EntryDraft.noteLimit))
                }
                .onReceive(Self.textDidChange) { notification in
                    guard let textView = notification.object as? UITextView,
                          textView.isFirstResponder else { return }
                    let kept = String(textView.text.prefix(EntryDraft.noteLimit))
                    guard kept != textView.text else { return }
                    textView.text = kept
                    note = kept
                }
        }
    }

    private func counterText(_ counter: NoteCounter) -> LocalizedStringResource {
        switch counter {
        case let .left(count): "\(count) characters left"
        case .limitReached: "Character limit reached"
        }
    }
}
