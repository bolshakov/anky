// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiListView: View {
    let model: BasdaiModel
    @State private var isShowingForm = false
    @State private var basdaiSave = BasdaiSave()
    @State private var saveTicks = 0

    var body: some View {
        List {
            if model.results.isEmpty {
                Section {
                    BasdaiEmptyBlock()
                        .nonCardBlock()
                }
                .emptyBlockGap()
            } else {
                CardSection(footnote: footnote, id: "basdai-results") {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, result in
                        BasdaiResultRow(result: result)
                            .accessibilityIdentifier("basdai-row-\(index)")
                    }
                }
            }
        }
        .screenSpacing()
        .accessibilityIdentifier("basdai-screen")
        .navigationTitle("BASDAI")
        .navigationBarTitleDisplayMode(.inline)
        .bottomPrimaryButton(Text("Start"), id: "basdai-start", action: start)
        .sheet(isPresented: $isShowingForm) {
            BasdaiFormView(onSave: save)
        }
        .sensoryFeedback(.success, trigger: saveTicks)
    }

    private func start() {
        basdaiSave = BasdaiSave()
        isShowingForm = true
    }

    private func save(_ answers: [Int]) throws {
        if try basdaiSave.save(answers, at: .now, add: model.add) {
            saveTicks += 1
        }
    }

    private var footnote: Text {
        Text("""
        Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). \
        Swipe left to delete.
        """)
    }
}
