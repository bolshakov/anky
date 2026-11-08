// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseCheckInSection: View {
    @Binding var checkIn: DoseCheckIn

    var body: some View {
        CardSection(footnote: footnote, id: "check-in") { rows }
    }

    @ViewBuilder private var rows: some View {
        Toggle("Check in later", isOn: $checkIn.isOn)
            .accessibilityIdentifier("check-in-later")
        if checkIn.isOn {
            DoseCheckInMenu(delay: $checkIn.delay)
        }
    }

    private var footnote: Text {
        let ask = Text("Anky will ask how you feel after this long.")
        guard !checkIn.isOn else { return ask }
        return Text("\(ask) \(Text("Turn it on to choose a time."))")
    }
}
