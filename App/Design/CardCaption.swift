// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func cardCaption() -> some View {
        textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(ListHeaderEdgeInset())
    }
}

private struct ListHeaderEdgeInset: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.listRowInsets(.leading, 0)
        } else {
            content
        }
    }
}
