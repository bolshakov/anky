// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

private struct BasdaiDeleteConfirmation: ViewModifier {
    let target: BasdaiResult?
    let onDismiss: () -> Void
    let model: BasdaiModel
    let onDeleted: () -> Void

    private var isPresented: Binding<Bool> {
        Binding(
            get: { target != nil },
            set: { isShowing in
                if !isShowing {
                    onDismiss()
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content.entryDeleteConfirmation(isPresented: isPresented, words: .basdai) {
            guard let target else { return }
            try model.remove(id: target.id)
            onDeleted()
        }
    }
}

extension View {
    /// Asks before deleting `target` from `model`, and calls `onDeleted` once it is gone. `target` is a value and not a
    /// binding, so the screen that holds it reads it and rebuilds its list when the question closes. A list whose
    /// screen does not read it leaves the swiped row removed after Cancel.
    func basdaiDeleteConfirmation(
        of target: BasdaiResult?,
        onDismiss: @escaping () -> Void,
        model: BasdaiModel,
        onDeleted: @escaping () -> Void
    ) -> some View {
        modifier(BasdaiDeleteConfirmation(target: target, onDismiss: onDismiss, model: model, onDeleted: onDeleted))
    }
}
