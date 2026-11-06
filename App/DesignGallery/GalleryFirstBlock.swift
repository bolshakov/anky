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

        private func pill(_ title: String, id: String) -> some View {
            Text(verbatim: title)
                .rowHeight()
                .background(Color.clear.accessibilityElement().accessibilityLabel(title).accessibilityIdentifier(id))
        }

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
                        pill("Left pill", id: "gallery-pill-left")
                        pill("Right pill", id: "gallery-pill-right")
                        Spacer(minLength: .zero)
                    }
                }
                .nonCardBlock()
            }
        }
    }
#endif
