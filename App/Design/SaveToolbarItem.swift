// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    /// `isEnabled` dims the button alone, since `.disabled` on this modifier would disable the form it sits on.
    func saveToolbarItem(id: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm, action: action)
                    .accessibilityLabel("Save")
                    .accessibilityIdentifier(id)
                    .disabled(!isEnabled)
            }
        }
    }
}
