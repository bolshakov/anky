// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct CheckInDelayMenu: View {
    @Binding var checkInAfter: CheckInDelay?

    var body: some View {
        Menu {
            Picker("After", selection: $checkInAfter) {
                ForEach(CheckInChoices.all, id: \.self) { choice in
                    Text(title(for: choice)).tag(choice)
                }
            }
            .labelsHidden()
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("After").foregroundStyle(.primary)
                    Spacer()
                    valueAndChevron
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("After").foregroundStyle(.primary)
                    valueAndChevron
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(String(localized: "Check in after") + ", " + String(localized: title(for: checkInAfter)))
        .accessibilityIdentifier("check-in-after")
    }

    private var valueAndChevron: some View {
        HStack {
            Text(title(for: checkInAfter))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.secondary)
                .imageScale(.small)
        }
    }

    private func title(for choice: CheckInDelay?) -> LocalizedStringResource {
        choice?.title ?? "Off"
    }
}
