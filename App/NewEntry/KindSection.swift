import AnkyDomain
import SwiftUI

struct KindSection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        Picker("Kind", selection: $draft.kind) {
            ForEach(EntryKind.allCases, id: \.self) { kind in
                Text(kind.title).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityIdentifier("kind-picker")
    }
}
