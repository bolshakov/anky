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
        Section {
            TextField("Add a note", text: $note, axis: .vertical)
                .font(.body)
                .focused($isFocused)
                .accessibilityLabel("Note")
                .accessibilityIdentifier("note-field")
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isFocused = true }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("note-card")
                .listRowInsets(EdgeInsets())
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
        } footer: {
            if let counter = draft.noteCounter {
                Text(counterText(counter))
                    .accessibilityIdentifier("note-counter")
            }
        }
    }

    private func counterText(_ counter: NoteCounter) -> LocalizedStringResource {
        switch counter {
        case let .left(count): "\(count) left"
        case .limitReached: "Limit reached"
        }
    }
}
