// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct PrivacyPolicyView: View {
    private let blocks = Self.load()

    var body: some View {
        Group {
            if blocks.isEmpty {
                ContentUnavailableView("Privacy Policy", systemImage: "doc.text")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                            PolicyBlockView(block: block)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, topGap(at: index))
                        }
                    }
                }
                .readingScreenSpacing()
            }
        }
        .background(Color.surface)
        .accessibilityIdentifier("privacy-policy-screen")
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func topGap(at index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        if case .listItem = blocks[index], case .listItem = blocks[index - 1] {
            return Spacing.listItemGap
        }
        return Spacing.readingBlockGap
    }

    private static func load() -> [PolicyBlock] {
        guard let url = Bundle.main.url(forResource: "PRIVACY", withExtension: "md"),
              let markdown = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return PolicyBlock.blocks(from: markdown)
    }
}
