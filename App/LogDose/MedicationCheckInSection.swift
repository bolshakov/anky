// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationCheckInSection: View {
    @Binding var checkIn: DoseCheckIn

    var body: some View {
        CardSection(footnote: footnote, id: "check-in") {
            SwitchRow(Text("Check in later"), isOn: $checkIn.isOn)
                .accessibilityIdentifier("check-in-later")
            if checkIn.isOn {
                CheckInDelayRow(delay: $checkIn.delay)
            }
        }
    }

    private var footnote: Text {
        let ask = String(localized: "Anky will ask how you feel after this long.")
        guard !checkIn.isOn else { return Text(verbatim: ask) }
        return Text(verbatim: "\(ask) \(String(localized: "Turn it on to choose a time."))")
    }
}

private struct CheckInDelayRow: View {
    @Binding var delay: CheckInDelay
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Menu {
            Picker("After", selection: $delay) {
                ForEach(CheckInDelay.allCases, id: \.self) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .labelsHidden()
        } label: {
            layout
                .frame(maxWidth: .infinity, alignment: .leading)
                .rowHeight()
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .fillsCardRow()
        .accessibilityLabel("Check in after")
        .accessibilityValue(Text(delay.title))
        .accessibilityIdentifier("dose-check-in-after")
    }

    @ViewBuilder private var layout: some View {
        let title = Text("After").foregroundStyle(Color.ink)
        let value = HStack {
            Text(delay.title)
            Image(systemName: "chevron.up.chevron.down")
        }
        .foregroundStyle(Color.ink2)
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                title
                value
            }
        } else {
            HStack {
                title
                Spacer()
                value
            }
        }
    }
}
