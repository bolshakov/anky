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
            HStack {
                Text("After")
                    .foregroundStyle(.primary)
                Spacer()
                Text(title(for: checkInAfter))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Check in after")
        .accessibilityValue(String(localized: title(for: checkInAfter)))
        .accessibilityIdentifier("check-in-after")
    }

    private func title(for choice: CheckInDelay?) -> LocalizedStringResource {
        choice?.title ?? "Off"
    }
}
