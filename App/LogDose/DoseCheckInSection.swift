// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseCheckInSection: View {
    @Binding var checkIn: DoseCheckIn
    let readingKind: EntryKind?
    var isCard = false

    var body: some View {
        if isCard {
            CardSection(footnote: footnote, id: "check-in") { rows }
        } else {
            Section {
                rows
            } footer: {
                footnote
                    .font(.footnote)
                    .accessibilityIdentifier("check-in-footnote")
            }
        }
    }

    @ViewBuilder private var rows: some View {
        Toggle("Check in later", isOn: $checkIn.isOn)
            .accessibilityIdentifier("check-in-later")
        if checkIn.isOn {
            DoseCheckInMenu(delay: $checkIn.delay)
        }
    }

    private var footnote: Text {
        switch (readingKind, checkIn.isOn) {
        case (nil, true):
            Text("Anky asks how you feel after this long.")
        case (nil, false):
            Text("Anky asks how you feel after this long. Turn it on to choose a time.")
        case (.pain, true):
            Text("Anky asks how your pain is after this long.")
        case (.pain, false):
            Text("Anky asks how your pain is after this long. Turn it on to choose a time.")
        case (.stiffness, true):
            Text("Anky asks how stiff you are after this long.")
        case (.stiffness, false):
            Text("Anky asks how stiff you are after this long. Turn it on to choose a time.")
        case (.fatigue, true):
            Text("Anky asks how tired you are after this long.")
        case (.fatigue, false):
            Text("Anky asks how tired you are after this long. Turn it on to choose a time.")
        }
    }
}
