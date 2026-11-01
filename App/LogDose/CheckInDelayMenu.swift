// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct CheckInDelayMenu: View {
    @Binding var checkInAfter: CheckInDelay?

    var body: some View {
        Picker("After", selection: $checkInAfter) {
            ForEach(CheckInChoices.all, id: \.self) { choice in
                Text(title(for: choice)).tag(choice)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Check in after")
        .accessibilityIdentifier("check-in-after")
    }

    private func title(for choice: CheckInDelay?) -> LocalizedStringResource {
        choice?.title ?? "Off"
    }
}
