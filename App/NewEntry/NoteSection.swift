import AnkyDomain
import SwiftUI

struct NoteSection: View {
    @Binding var draft: EntryDraft

    private var charactersLeft: Int {
        EntryDraft.noteLimit - draft.note.count
    }

    private var counterText: String {
        charactersLeft == 0 ? "Limit reached" : "\(charactersLeft) left"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            NoteTextView(text: $draft.note)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle.card
                        .fill(Color("CardBackground"))
                        .accessibilityIdentifier("note-card")
                }

            if charactersLeft < 40 {
                Text(counterText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("note-counter")
            }
        }
    }
}
