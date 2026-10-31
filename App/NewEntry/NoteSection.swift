// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct NoteSection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            NoteTextView(text: $draft.note)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle.card
                        .fill(Color("CardBackground"))
                        .accessibilityIdentifier("note-card")
                }

            if let counter = draft.noteCounter {
                Text(counterText(counter))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
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
