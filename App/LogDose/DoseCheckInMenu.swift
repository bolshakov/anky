// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseCheckInMenu: View {
    @Binding var delay: CheckInDelay

    var body: some View {
        Menu {
            Picker("After", selection: $delay) {
                ForEach(CheckInDelay.allCases, id: \.self) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .labelsHidden()
        } label: {
            // At accessibility sizes the value does not fit beside the label, so it stacks under it.
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("After")
                        .foregroundStyle(.primary)
                    Spacer()
                    value
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("After")
                        .foregroundStyle(.primary)
                    value
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Check in after")
        .accessibilityValue(String(localized: delay.title))
        .accessibilityIdentifier("dose-check-in-after")
    }

    private var value: some View {
        HStack {
            Text(delay.title)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(.secondary)
        }
    }
}
