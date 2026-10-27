import AnkyDomain
import SwiftUI

struct NoteSection: View {
    @Binding var draft: EntryDraft
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Add a note", text: $draft.note, axis: .vertical)
            .focused($isFocused)
            .accessibilityIdentifier("note-field")
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .accessibilityIdentifier("note-card")
            }
    }
}
