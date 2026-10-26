import AnkyDomain
import SwiftUI

struct NoteSection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        TextField("Add a note", text: $draft.note, axis: .vertical)
            .accessibilityIdentifier("note-field")
            .frame(minHeight: 44, alignment: .topLeading)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
