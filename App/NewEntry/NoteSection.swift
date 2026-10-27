import AnkyDomain
import SwiftUI

struct NoteSection: View {
    @Binding var draft: EntryDraft

    private var charactersLeft: Int {
        EntryDraft.noteLimit - draft.note.count
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            NoteTextView(text: $draft.note)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("CardBackground"))
                        .accessibilityIdentifier("note-card")
                }

            if charactersLeft < 40 {
                Text("\(charactersLeft) left")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("note-counter")
            }
        }
    }
}
