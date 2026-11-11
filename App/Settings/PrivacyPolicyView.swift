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
                    LazyVStack(alignment: .leading, spacing: Spacing.readingBlockGap) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                            PolicyBlockView(block: block)
                                .frame(maxWidth: .infinity, alignment: .leading)
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

    private static func load() -> [PolicyBlock] {
        guard let url = Bundle.main.url(forResource: "PRIVACY", withExtension: "md"),
              let markdown = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }
        return PolicyBlock.blocks(from: markdown)
    }
}
