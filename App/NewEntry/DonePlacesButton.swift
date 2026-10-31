// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DonePlacesButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PinnedButtonStyle())
        .accessibilityIdentifier("done-places")
    }

    private var title: LocalizedStringResource {
        if count == 0 {
            return "Done"
        }
        return "Done · \(count) places"
    }
}
