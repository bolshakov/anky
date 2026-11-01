// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct KindSection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        Picker("What are you logging", selection: $draft.kind) {
            ForEach(EntryKind.allCases, id: \.self) { kind in
                Text(kind.displayName).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("What are you logging")
        .accessibilityIdentifier("kind-picker")
        .sensoryFeedback(.selection, trigger: draft.kind)
    }
}
