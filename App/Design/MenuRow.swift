// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct MenuRow<Value: Hashable, Options: View>: View {
    let title: Text
    @Binding var selection: Value
    let options: Options

    init(_ title: Text, selection: Binding<Value>, @ViewBuilder options: () -> Options) {
        self.title = title
        _selection = selection
        self.options = options()
    }

    var body: some View {
        Picker(selection: $selection) {
            options
        } label: {
            title.foregroundStyle(Color.ink)
        }
        .pickerStyle(.menu)
        .tint(Color.ink2)
        .rowHeight()
        .accessibilityElement(children: .combine)
    }
}
