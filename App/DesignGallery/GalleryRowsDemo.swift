// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import SwiftUI

    struct GalleryRowsDemo: View {
        private enum Choice: CaseIterable {
            case first, second, third

            var title: String {
                switch self {
                case .first: "Choice A"
                case .second: "Choice B"
                case .third: "Choice C"
                }
            }
        }

        @State private var choice = Choice.first
        @State private var isOn = true
        @State private var chosenIsFirst = true

        var body: some View {
            CardSection(Text(verbatim: "Rows"), id: "gallery-rows") {
                ValueRow(Text(verbatim: "Value row"), value: Text(verbatim: "Some value")) {}
                    .accessibilityIdentifier("gallery-value-row")
                MenuRow(Text(verbatim: "Menu row"), selection: $choice) {
                    ForEach(Choice.allCases, id: \.self) { Text(verbatim: $0.title) }
                }
                .accessibilityIdentifier("gallery-menu-row")
                SwitchRow(Text(verbatim: "Switch row"), isOn: $isOn)
                    .accessibilityIdentifier("gallery-switch-row")
                TintRow(Text(verbatim: "Chosen row"), isSelected: chosenIsFirst) { chosenIsFirst = true }
                    .accessibilityIdentifier("gallery-tint-row")
                TintRow(Text(verbatim: "Other row"), isSelected: !chosenIsFirst) { chosenIsFirst = false }
                    .accessibilityIdentifier("gallery-tint-row-other")
                TwoLineRow(
                    Text(verbatim: "Two-line row"),
                    subtitle: Text(verbatim: "A second line of text"),
                    value: Text(verbatim: "Value")
                )
                .accessibilityIdentifier("gallery-two-line-row")
            }
        }
    }
#endif
