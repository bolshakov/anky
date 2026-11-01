// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct TakenAsControl: View {
    @Binding var takenAs: TakenAs
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 4) { segments }
            } else {
                HStack(spacing: 4) { segments }
            }
        }
        .padding(4)
        .background(Color("CardBackground"), in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How you take it")
        .sensoryFeedback(.selection, trigger: takenAs)
    }

    private var segments: some View {
        ForEach(TakenAs.allCases, id: \.self) { option in
            segment(option)
        }
    }

    private func segment(_ option: TakenAs) -> some View {
        let isSelected = option == takenAs
        return Button {
            takenAs = option
        } label: {
            Text(option.title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color("OnSoftAccent") : .primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? Color("SoftAccent") : .clear, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("taken-\(option.rawValue)")
    }
}
