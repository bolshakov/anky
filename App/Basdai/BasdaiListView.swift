// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct BasdaiListView: View {
    let model: BasdaiModel

    var body: some View {
        List {
            if model.results.isEmpty {
                Section {
                    BasdaiEmptyBlock()
                        .nonCardBlock()
                }
                .emptyBlockGap()
            } else {
                CardSection(footnote: footnote, id: "basdai-results") {}
            }
        }
        .screenSpacing()
        .accessibilityIdentifier("basdai-screen")
        .navigationTitle("BASDAI")
        .navigationBarTitleDisplayMode(.inline)
        .bottomPrimaryButton(Text("Start"), id: "basdai-start") {}
    }

    private var footnote: Text {
        Text("""
        Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). \
        Swipe left to delete.
        """)
    }
}
