// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

extension View {
    func basdaiSheet(isPresented: Binding<Bool>, model: BasdaiModel, onDismiss: @escaping () -> Void) -> some View {
        modifier(BasdaiSheet(isPresented: isPresented, model: model, onDismiss: onDismiss))
    }
}

private struct BasdaiSheet: ViewModifier {
    @Binding var isPresented: Bool
    let model: BasdaiModel
    let onDismiss: () -> Void
    @State private var basdaiSave = BasdaiSave()
    @State private var saveTicks = 0

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                BasdaiFormView(onSave: save)
            }
            .onChange(of: isPresented) { _, isShowing in
                if isShowing {
                    basdaiSave = BasdaiSave()
                }
            }
            .sensoryFeedback(.success, trigger: saveTicks)
    }

    private func save(_ answers: [Int]) throws {
        if try basdaiSave.save(answers, at: .now, add: model.add) {
            saveTicks += 1
        }
    }
}
