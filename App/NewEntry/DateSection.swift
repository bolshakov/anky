// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DateSection: View {
    @Binding var date: Date
    @State private var isShowingPicker = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isShowingPicker.toggle()
            } label: {
                HStack {
                    Text("Date and time")
                    Spacer()
                    Text("\(day), \(clock)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("date-row")
            .accessibilityLabel("Date and time")
            .accessibilityValue(Text([day, clock].joined(separator: " ")))
            if isShowingPicker {
                DatePicker(
                    "Date and time",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .accessibilityIdentifier("date-picker")
            }
        }
        .background(Color("CardBackground"), in: .card)
    }

    private var day: String {
        switch ShortDayText.day(for: date, now: .now, calendar: .current, locale: .current) {
        case .today:
            String(localized: "Today")
        case .yesterday:
            String(localized: "Yesterday")
        case let .sameYear(shortDay):
            shortDay
        case let .otherYear(shortDay, year):
            String(localized: "\(shortDay) \(year)")
        }
    }

    private var clock: String {
        ClockText.text(for: date, calendar: .current, locale: .current)
    }
}
