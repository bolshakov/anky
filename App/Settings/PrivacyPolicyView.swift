// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct PrivacyPolicyView: View {
    private let policy = Self.load()

    var body: some View {
        Group {
            if let policy {
                ScrollView {
                    Text(policy)
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .readingScreenSpacing()
            } else {
                ContentUnavailableView("Privacy Policy", systemImage: "doc.text")
            }
        }
        .background(Color.surface)
        .accessibilityIdentifier("privacy-policy-screen")
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func load() -> AttributedString? {
        guard let url = Bundle.main.url(forResource: "PRIVACY", withExtension: "md"),
              let markdown = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )
    }
}
