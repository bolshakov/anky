// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseCheckInMenu: View {
    @Binding var delay: CheckInDelay
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Menu {
            Picker("After", selection: $delay) {
                ForEach(CheckInDelay.allCases, id: \.self) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .labelsHidden()
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After")
                            .foregroundStyle(.primary)
                        value
                    }
                } else {
                    HStack {
                        Text("After")
                            .foregroundStyle(.primary)
                        Spacer()
                        value
                    }
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
