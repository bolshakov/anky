// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func cardCaption() -> some View {
        textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.leading, 0)
    }
}
