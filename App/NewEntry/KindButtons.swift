// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct KindButtons: View {
    @Binding var kind: EntryKind

    var body: some View {
        VStack(spacing: 8) {
            ForEach(EntryKind.allCases, id: \.self) { option in
                let isSelected = option == kind
                Button {
                    kind = option
                } label: {
                    Text(option.displayName)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(isSelected ? Color("AccentColor") : .primary)
                        .background(
                            isSelected
                                ? Color("AccentColor").opacity(0.15)
                                : Color("CardBackground"),
                            in: .card
                        )
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("kind-\(option.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kind-picker")
        .sensoryFeedback(.selection, trigger: kind)
    }
}
