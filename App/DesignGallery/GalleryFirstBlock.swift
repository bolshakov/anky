// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import SwiftUI

    struct GalleryFirstBlock: View {
        private enum Kind: CaseIterable {
            case first, second, third

            var title: String {
                switch self {
                case .first: "First"
                case .second: "Second"
                case .third: "Third"
                }
            }
        }

        @State private var kind = Kind.first

        var body: some View {
            Section {
                VStack(spacing: Spacing.inlineGap) {
                    Picker(selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { Text(verbatim: $0.title) }
                    } label: {
                        Text(verbatim: "Kind")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("gallery-kind")
                    HStack(spacing: Spacing.inlineGap) {
                        Text(verbatim: "Left pill").accessibilityIdentifier("gallery-pill-left")
                        Text(verbatim: "Right pill").accessibilityIdentifier("gallery-pill-right")
                        Spacer(minLength: .zero)
                    }
                }
                .nonCardBlock()
            }
        }
    }
#endif
