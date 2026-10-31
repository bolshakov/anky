// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func pinLimitAlert(_ shortcuts: ShortcutsModel) -> some View {
        modifier(PinLimitAlertModifier(shortcuts: shortcuts))
    }
}

private struct PinLimitAlertModifier: ViewModifier {
    @Bindable var shortcuts: ShortcutsModel

    func body(content: Content) -> some View {
        content.alert(
            Text("You can pin up to 5. Unpin one to add another."),
            isPresented: $shortcuts.isShowingPinLimit
        ) {
            Button("OK") {}
        }
    }
}
