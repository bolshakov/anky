// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DonePlacesButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .accessibilityLabel(spokenTitle)
        .accessibilityIdentifier("done-places")
    }

    private var title: LocalizedStringResource {
        if count == 0 {
            return "Done"
        }
        return "Done · \(count) places"
    }

    private var spokenTitle: String {
        if count == 0 {
            return String(localized: "Done")
        }
        return [String(localized: "Done"), String(localized: "\(count) places")].joined(separator: ", ")
    }
}
