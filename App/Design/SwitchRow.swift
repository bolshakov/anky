// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct SwitchRow: View {
    let title: Text
    @Binding var isOn: Bool

    init(_ title: Text, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            title.foregroundStyle(Color.ink)
        }
        .tint(Color.tint)
        .rowHeight()
    }
}
